import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { db } from "../lib/admin";

/**
 * Maintain ratingAvg + ratingCount on a business when reviews are written.
 * Uses a transaction with a server-only ratingSum so the average stays exact.
 */
export const onReviewWrite = onDocumentWritten(
  "businesses/{businessId}/reviews/{reviewerUid}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;

    const beforeRating = before?.exists ? Number(before.get("rating") ?? 0) : 0;
    const afterRating = after?.exists ? Number(after.get("rating") ?? 0) : 0;
    const countDelta = (after?.exists ? 1 : 0) - (before?.exists ? 1 : 0);
    const sumDelta = afterRating - beforeRating;
    if (countDelta === 0 && sumDelta === 0) return;

    const ref = db.doc(`businesses/${event.params.businessId}`);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const sum = (snap.get("ratingSum") as number | undefined) ?? 0;
      const count = (snap.get("ratingCount") as number | undefined) ?? 0;
      const newSum = sum + sumDelta;
      const newCount = Math.max(0, count + countDelta);
      tx.set(
        ref,
        {
          ratingSum: newSum,
          ratingCount: newCount,
          ratingAvg: newCount > 0 ? newSum / newCount : 0,
        },
        { merge: true }
      );
    });
  }
);
