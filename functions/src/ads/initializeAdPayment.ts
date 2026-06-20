import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

const PAYSTACK_SECRET = defineSecret("PAYSTACK_SECRET");

/** Fund an ad campaign (advertiser-chosen budget) via Paystack hosted checkout. */
export const initializeAdPayment = onCall(
  { secrets: [PAYSTACK_SECRET], enforceAppCheck: false },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const campaignId = String(req.data?.campaignId ?? "");
    const ref = db.doc(`adCampaigns/${campaignId}`);
    const snap = await ref.get();
    if (!snap.exists || snap.get("advertiserId") !== uid) {
      throw new HttpsError("permission-denied", "Not your campaign.");
    }
    if (snap.get("status") !== "draft") {
      throw new HttpsError("failed-precondition", "Campaign is not a draft.");
    }

    const budget = (snap.get("budget") as Record<string, any>) ?? {};
    const amount = Number(budget.total ?? 0);
    const currency = String(budget.currency ?? "NGN");
    if (amount <= 0) throw new HttpsError("invalid-argument", "Set a campaign budget first.");

    const privateSnap = await db.doc(`users/${uid}/private/profile`).get();
    const email = (privateSnap.get("email") as string | undefined) ?? `${uid}@users.myspot.app`;

    const reference = `ad_${campaignId}_${Date.now()}`;
    const metadata = { userId: uid, purpose: "ad", relatedId: campaignId, plan: null };

    await db.doc(`paymentIntents/${reference}`).set({
      userId: uid,
      purpose: "ad",
      relatedId: campaignId,
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
