import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { grantUserVerification, grantBusinessVerification } from "../lib/entitlements";
import { notify } from "../lib/notifications";

/** Admin/moderator: approve or reject a paid verification request (in_review only). */
export const approveVerification = onCall({ enforceAppCheck: true }, async (req) => {
  const role = req.auth?.token.role;
  if (role !== "admin" && role !== "moderator") {
    throw new HttpsError("permission-denied", "Moderators only.");
  }

  const requestId = String(req.data?.requestId ?? "");
  const approve = req.data?.approve === true;
  const note = (req.data?.note as string | undefined) ?? null;
  if (!requestId) throw new HttpsError("invalid-argument", "requestId required.");

  const ref = db.doc(`verificationRequests/${requestId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Request not found.");
  if (snap.get("status") !== "in_review") {
    throw new HttpsError("failed-precondition", "Request is not awaiting review.");
  }

  const userId = snap.get("userId") as string;
  const subjectType = snap.get("subjectType") as string;
  const subjectId = snap.get("subjectId") as string;

  if (approve) {
    if (subjectType === "business") {
      await grantBusinessVerification(subjectId);
    } else {
      await grantUserVerification(userId);
    }
  }

  await ref.set(
    {
      status: approve ? "approved" : "rejected",
      reviewerId: req.auth!.uid,
      reviewNote: note,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await db.collection("adminAudit").add({
    adminId: req.auth!.uid,
    action: approve ? "verify_approve" : "verify_reject",
    targetType: "verificationRequest",
    targetId: requestId,
    after: { status: approve ? "approved" : "rejected" },
    at: FieldValue.serverTimestamp(),
  });

  await notify({
    toUid: userId,
    type: "system",
    actor: { uid: "system", displayName: "MySpot" },
    text: approve ? "You're verified! 🎉" : `Verification declined${note ? ": " + note : "."}`,
  });

  return { ok: true };
});
