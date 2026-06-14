import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin";
import { grantPremium } from "./entitlements";
import { notify } from "./notifications";

const SYSTEM = { uid: "system", displayName: "MySpot" };

export type PaymentMeta = {
  userId: string;
  purpose: string;
  plan?: string | null;
  relatedId?: string | null;
};

/**
 * Idempotently record a successful payment and grant its entitlement. Called only
 * from signature-verified webhooks. The ledger doc id is the provider reference,
 * so duplicate webhook deliveries are no-ops.
 *
 * Verification payments advance the request to `in_review` (admin approves to
 * actually grant the badge — payment-before-review). Premium payments activate
 * the subscription immediately.
 */
export async function fulfillPayment(params: {
  reference: string;
  provider: string;
  amount: number;
  currency: string;
  meta: PaymentMeta;
}): Promise<void> {
  const { reference, provider, amount, currency, meta } = params;

  const fresh = await db.runTransaction(async (tx) => {
    const payRef = db.doc(`payments/${reference}`);
    if ((await tx.get(payRef)).exists) return false;
    tx.set(payRef, {
      userId: meta.userId,
      provider,
      providerRef: reference,
      purpose: meta.purpose,
      amount,
      currency,
      status: "succeeded",
      metadata: meta,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(db.doc(`paymentIntents/${reference}`), { status: "succeeded" }, { merge: true });
    return true;
  });
  if (!fresh) return; // already processed

  if (meta.purpose === "verification" && meta.relatedId) {
    await db.doc(`verificationRequests/${meta.relatedId}`).set(
      { status: "in_review", paymentId: reference, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    await notify({
      toUid: meta.userId,
      type: "system",
      actor: SYSTEM,
      text: "Payment received — your verification is under review.",
    });
  } else if (meta.purpose === "premium") {
    await grantPremium(meta.userId, meta.plan ?? "pro", provider);
    await notify({
      toUid: meta.userId,
      type: "system",
      actor: SYSTEM,
      text: "Welcome to MySpot Premium!",
    });
  } else if (meta.purpose === "ad" && meta.relatedId) {
    await db.doc(`adCampaigns/${meta.relatedId}`).set(
      { status: "pending_review", paymentId: reference, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
    await notify({
      toUid: meta.userId,
      type: "system",
      actor: { uid: "system", displayName: "MySpot Ads" },
      text: "Campaign funded — it's now under review.",
    });
  }
}
