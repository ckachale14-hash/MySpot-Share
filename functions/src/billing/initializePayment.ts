import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { priceFor, Plan, Purpose } from "../lib/fees";

const PAYSTACK_SECRET = defineSecret("PAYSTACK_SECRET");

/**
 * Initialize a hosted Paystack checkout for verification or premium. Returns an
 * `authorizationUrl` the client opens; fulfillment happens later in the webhook
 * (mobile-money/card flows complete out-of-band, so the webhook is the only
 * source of truth). A server-side `paymentIntents/{reference}` records intent.
 */
export const initializePayment = onCall(
  { secrets: [PAYSTACK_SECRET], enforceAppCheck: false },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const purpose = (req.data?.purpose ?? "premium") as Purpose;
    const plan = req.data?.plan as Plan | undefined;
    const relatedId = req.data?.relatedId as string | undefined;
    if (purpose === "verification" && !relatedId) {
      throw new HttpsError("invalid-argument", "relatedId (requestId) is required.");
    }

    const { amount, currency } = priceFor(purpose, plan);

    const privateSnap = await db.doc(`users/${uid}/private/profile`).get();
    const email = (privateSnap.get("email") as string | undefined) ?? `${uid}@users.myspot.app`;

    const reference = `${purpose}_${uid}_${Date.now()}`;
    const metadata = { userId: uid, purpose, plan: plan ?? null, relatedId: relatedId ?? null };

    await db.doc(`paymentIntents/${reference}`).set({
      userId: uid,
      purpose,
      plan: plan ?? null,
      relatedId: relatedId ?? null,
      amount,
      currency,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    const resp = await fetch("https://api.paystack.co/transaction/initialize", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${PAYSTACK_SECRET.value()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, amount, currency, reference, metadata }),
    });

    const json = (await resp.json()) as {
      status?: boolean;
      data?: { authorization_url?: string };
      message?: string;
    };
    if (!resp.ok || !json.status || !json.data?.authorization_url) {
      throw new HttpsError("internal", `Payment init failed: ${json.message ?? resp.status}`);
    }

    return { authorizationUrl: json.data.authorization_url, reference };
  }
);
