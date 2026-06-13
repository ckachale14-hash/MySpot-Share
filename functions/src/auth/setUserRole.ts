import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db, adminAuth } from "../lib/admin";

const ROLES = ["user", "moderator", "admin"] as const;

/**
 * Admin-only: set a user's role. Updates the custom claim (authority) and the
 * mirrored users/{uid}.role field, and writes an audit record.
 */
export const setUserRole = onCall({ enforceAppCheck: true }, async (req) => {
  if (req.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin only.");
  }

  const { uid, role } = (req.data ?? {}) as { uid?: string; role?: string };
  if (!uid || !role || !ROLES.includes(role as (typeof ROLES)[number])) {
    throw new HttpsError("invalid-argument", "Provide a valid uid and role.");
  }

  const current = (await adminAuth.getUser(uid)).customClaims ?? {};
  await adminAuth.setCustomUserClaims(uid, { ...current, role });
  await db.doc(`users/${uid}`).update({ role });

  await db.collection("adminAudit").add({
    adminId: req.auth.uid,
    action: "set_role",
    targetType: "user",
    targetId: uid,
    after: { role },
    at: FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
