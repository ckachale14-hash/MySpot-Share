import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { fulfillPayment } from "../lib/fulfill";

const FLUTTERWAVE_WEBHOOK_HASH = defineSecret("FLUTTERWAVE_WEBHOOK_HASH");

/**
 * Flutterwave webhook: verify the `verif-hash` header against the configured
 * secret hash, then fulfill on a successful charge. (In production, also re-query
 * Flutterwave's verify endpoint before granting high-value entitlements.)
 */
export const flutterwaveWebhook = onRequest(
  { secrets: [FLUTTERWAVE_WEBHOOK_HASH] },
  async (req, res) => {
    const sig = req.headers["verif-hash"] as string | undefined;
    if (!sig || sig !== FLUTTERWAVE_WEBHOOK_HASH.value()) {
      res.status(401).send("invalid signature");
      return;
    }

    const body = req.body as { event?: string; data?: Record<string, any> };
    const d = body.data;
    if (body.event === "charge.completed" && d?.status === "successful") {
      const meta = (d.meta ?? {}) as Record<string, any>;
      if (meta.userId && meta.purpose) {
        await fulfillPayment({
          reference: String(d.tx_ref ?? d.flw_ref),
          provider: "flutterwave",
          amount: Number(d.amount),
          currency: String(d.currency),
          meta: {
            userId: meta.userId,
            purpose: meta.purpose,
            plan: meta.plan ?? null,
            relatedId: meta.relatedId ?? null,
          },
        });
      }
    }
    res.sendStatus(200);
  }
);
