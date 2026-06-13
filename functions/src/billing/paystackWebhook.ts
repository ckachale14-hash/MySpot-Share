import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as crypto from "crypto";
import { fulfillPayment } from "../lib/fulfill";

const PAYSTACK_SECRET = defineSecret("PAYSTACK_SECRET");

/** Paystack webhook: verify the HMAC-SHA512 signature, then fulfill on success. */
export const paystackWebhook = onRequest({ secrets: [PAYSTACK_SECRET] }, async (req, res) => {
  const signature = req.headers["x-paystack-signature"] as string | undefined;
  const expected = crypto
    .createHmac("sha512", PAYSTACK_SECRET.value())
    .update(req.rawBody)
    .digest("hex");
  if (!signature || signature !== expected) {
    res.status(401).send("invalid signature");
    return;
  }

  const event = req.body as { event?: string; data?: Record<string, any> };
  if (event.event === "charge.success" && event.data) {
    const d = event.data;
    const meta = (d.metadata ?? {}) as Record<string, any>;
    if (meta.userId && meta.purpose) {
      await fulfillPayment({
        reference: String(d.reference),
        provider: "paystack",
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
});
