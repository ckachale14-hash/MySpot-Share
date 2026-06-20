import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

/**
 * Record an ad impression or click on an active campaign. Metrics are server-only
 * (clients can't write them directly), so this runs as a trusted callable.
 */
export const meterAdEvent = onCall({ enforceAppCheck: false }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const campaignId = String(req.data?.campaignId ?? "");
  const type = req.data?.type === "click" ? "click" : "impression";
  if (!campaignId) throw new HttpsError("invalid-argument", "campaignId required.");

  const ref = db.doc(`adCampaigns/${campaignId}`);
  const snap = await ref.get();
  if (!snap.exists || snap.get("status") !== "active") return { ok: true };

  const field = type === "click" ? "metrics.clicks" : "metrics.impressions";
  await ref.update({ [field]: FieldValue.increment(1) });
  return { ok: true };
});
