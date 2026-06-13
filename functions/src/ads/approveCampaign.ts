import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { notify } from "../lib/notifications";

/** Admin/moderator: approve or reject a funded ad campaign (pending_review only).
 * Approving marks the boosted post as sponsored so it surfaces with a label. */
export const approveCampaign = onCall({ enforceAppCheck: true }, async (req) => {
  const role = req.auth?.token.role;
  if (role !== "admin" && role !== "moderator") {
    throw new HttpsError("permission-denied", "Moderators only.");
  }
  const campaignId = String(req.data?.campaignId ?? "");
  const approve = req.data?.approve === true;
  const note = (req.data?.note as string | undefined) ?? null;

  const ref = db.doc(`adCampaigns/${campaignId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Campaign not found.");
  if (snap.get("status") !== "pending_review") {
    throw new HttpsError("failed-precondition", "Campaign is not awaiting review.");
  }

  const advertiserId = snap.get("advertiserId") as string;
  const boostPostId = snap.get("boostPostId") as string | undefined;

  await ref.update({
    status: approve ? "active" : "rejected",
    reviewNote: note,
    updatedAt: FieldValue.serverTimestamp(),
  });

  if (approve && boostPostId) {
    await db.doc(`posts/${boostPostId}`).set({ isSponsored: true }, { merge: true });
  }

  await db.collection("adminAudit").add({
    adminId: req.auth!.uid,
    action: approve ? "ad_approve" : "ad_reject",
    targetType: "adCampaign",
    targetId: campaignId,
    after: { status: approve ? "active" : "rejected" },
    at: FieldValue.serverTimestamp(),
  });

  await notify({
    toUid: advertiserId,
    type: "system",
    actor: { uid: "system", displayName: "MySpot Ads" },
    text: approve ? "Your campaign is live 🚀" : `Campaign declined${note ? ": " + note : "."}`,
  });

  return { ok: true };
});
