import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { VERIFICATION_FEE } from "../lib/fees";

type DocRef = { storagePath: string; kind: string };

/**
 * Open a verification application. The client first uploads KYC documents to its
 * private `verification/{uid}/...` Storage path, then calls this with the paths.
 * The request starts as `pending_payment`; only a verified payment webhook can
 * advance it to review (see billing/paystackWebhook).
 */
export const startVerification = onCall({ enforceAppCheck: false }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const subjectType = (req.data?.subjectType ?? "user") as "user" | "business";
  const subjectId = String(req.data?.subjectId ?? uid);
  const documents = (Array.isArray(req.data?.documents) ? req.data.documents : []) as DocRef[];

  if (documents.length === 0) {
    throw new HttpsError("invalid-argument", "Upload at least one document.");
  }
  // Documents must live under the caller's private KYC path.
  for (const d of documents) {
    if (!d.storagePath || !d.storagePath.startsWith(`verification/${uid}/`)) {
      throw new HttpsError("permission-denied", "Invalid document path.");
    }
  }
  if (subjectType === "business") {
    const biz = await db.doc(`businesses/${subjectId}`).get();
    if (!biz.exists || biz.get("ownerId") !== uid) {
      throw new HttpsError("permission-denied", "You don't own that business.");
    }
  }

  const ref = await db.collection("verificationRequests").add({
    userId: uid,
    subjectType,
    subjectId,
    documents,
    status: "pending_payment",
    amount: VERIFICATION_FEE.amount,
    currency: VERIFICATION_FEE.currency,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { requestId: ref.id };
});
