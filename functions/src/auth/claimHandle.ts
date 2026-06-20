import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

const HANDLE_RE = /^[a-z0-9_]{3,20}$/;

/**
 * Claim a unique @handle for the signed-in user. Handle uniqueness is enforced
 * server-side via a transaction on handles/{handle} (clients cannot write there).
 */
export const claimHandle = onCall({ enforceAppCheck: false }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const desired = String(req.data?.handle ?? "").toLowerCase().trim();
  if (!HANDLE_RE.test(desired)) {
    throw new HttpsError(
      "invalid-argument",
      "Handle must be 3–20 characters: lowercase letters, numbers, or _."
    );
  }

  const newRef = db.doc(`handles/${desired}`);
  const userRef = db.doc(`users/${uid}`);

  await db.runTransaction(async (tx) => {
    const existing = await tx.get(newRef);
    if (existing.exists && existing.get("uid") !== uid) {
      throw new HttpsError("already-exists", "That handle is taken.");
    }
    const userSnap = await tx.get(userRef);
    const oldHandle = userSnap.get("handle") as string | undefined;

    tx.set(newRef, { uid, createdAt: FieldValue.serverTimestamp() });
    tx.update(userRef, { handle: desired });
    if (oldHandle && oldHandle !== desired) {
      tx.delete(db.doc(`handles/${oldHandle}`));
    }
  });

  return { handle: desired };
});
