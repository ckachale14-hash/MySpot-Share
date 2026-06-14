import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { grantPremium, revokePremium } from "../lib/entitlements";
import { notify } from "../lib/notifications";

const REVENUECAT_WEBHOOK_AUTH = defineSecret("REVENUECAT_WEBHOOK_AUTH");

const GRANT = [
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
];
const REVOKE = ["CANCELLATION", "EXPIRATION", "SUBSCRIPTION_PAUSED"];

/** Map a RevenueCat entitlement/product id to a MySpot plan. */
function planFromEvent(event: Record<string, any>): string {
  const ent =
    (Array.isArray(event.entitlement_ids) && event.entitlement_ids[0]) ||
    event.entitlement_id ||
    event.product_id ||
    "";
  return String(ent).toLowerCase().includes("business") ? "business" : "pro";
}

/**
 * RevenueCat webhook — the source of truth for mobile (Play/StoreKit) premium
 * subscriptions. Verifies the configured Authorization header, then grants or
 * revokes premium. Idempotent on the RevenueCat event id.
 */
export const revenueCatWebhook = onRequest(
  { secrets: [REVENUECAT_WEBHOOK_AUTH] },
  async (req, res) => {
    const auth = req.headers["authorization"];
    if (!auth || auth !== `Bearer ${REVENUECAT_WEBHOOK_AUTH.value()}`) {
      res.status(401).send("invalid auth");
      return;
    }

    const event = (req.body?.event ?? {}) as Record<string, any>;
    const type = String(event.type ?? "");
    const uid = event.app_user_id as string | undefined;
    if (!uid) {
      res.sendStatus(200);
      return;
    }

    if (GRANT.includes(type)) {
      const reference = `revenuecat_${event.id ?? Date.now()}`;
      const plan = planFromEvent(event);
      const fresh = await db.runTransaction(async (tx) => {
        const payRef = db.doc(`payments/${reference}`);
        if ((await tx.get(payRef)).exists) return false;
        tx.set(payRef, {
          userId: uid,
          provider: "revenuecat",
          providerRef: String(event.id ?? ""),
          purpose: "premium",
          amount: event.price_in_purchased_currency ?? 0,
          currency: event.currency ?? "USD",
          status: "succeeded",
          metadata: { type, plan },
          createdAt: FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (fresh) {
        await grantPremium(uid, plan, "revenuecat");
        await notify({
          toUid: uid,
          type: "system",
          actor: { uid: "system", displayName: "MySpot" },
          text: "Premium activated — welcome!",
        });
      }
    } else if (REVOKE.includes(type)) {
      await revokePremium(uid, type === "EXPIRATION" ? "expired" : "canceled");
    }

    res.sendStatus(200);
  }
);
