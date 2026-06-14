import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

/**
 * Admin/moderator: resolve a content report. `remove` deletes the reported post
 * (which cascades counters via onPostDelete); `dismiss` just closes the report.
 * Every action is audited.
 */
export const resolveReport = onCall({ enforceAppCheck: true }, async (req) => {
  const role = req.auth?.token.role;
  if (role !== "admin" && role !== "moderator") {
    throw new HttpsError("permission-denied", "Moderators only.");
  }

  const reportId = String(req.data?.reportId ?? "");
  const action = req.data?.action === "remove" ? "remove" : "dismiss";
  if (!reportId) throw new HttpsError("invalid-argument", "reportId required.");

  const ref = db.doc(`reports/${reportId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Report not found.");

  const targetType = snap.get("targetType") as string | undefined;
  const targetId = snap.get("targetId") as string | undefined;

  if (action === "remove" && targetType === "post" && targetId) {
    await db.doc(`posts/${targetId}`).delete().catch(() => undefined);
  }

  await ref.update({
    status: "resolved",
    action,
    reviewerId: req.auth!.uid,
    resolvedAt: FieldValue.serverTimestamp(),
  });

  await db.collection("adminAudit").add({
    adminId: req.auth!.uid,
    action: `report_${action}`,
    targetType: targetType ?? null,
    targetId: targetId ?? null,
    at: FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
