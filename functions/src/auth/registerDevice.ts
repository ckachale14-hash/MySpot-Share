import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

/**
 * Register/unregister an FCM token in the user's private profile (server-only
 * collection). Called by the app after obtaining a messaging token.
 */
export const registerDevice = onCall({ enforceAppCheck: false }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const token = String(req.data?.token ?? "").trim();
  const remove = req.data?.remove === true;
  if (!token) throw new HttpsError("invalid-argument", "token is required.");

  await db.doc(`users/${uid}/private/profile`).set(
    {
      fcmTokens: remove
        ? FieldValue.arrayRemove(token)
        : FieldValue.arrayUnion(token),
    },
    { merge: true }
  );
  return { ok: true };
});
