import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

/**
 * Share edge at posts/{postId}/shares/{shareUid}. Maintains shareCount + score
 * on the post. Keyed by uid (one edge per sharer), so the count reflects unique
 * sharers — mirrors the like edge. Counters are server-only (clients can't write
 * shareCount), so this is the sole writer.
 */
export const onShareWrite = onDocumentWritten(
  "posts/{postId}/shares/{shareUid}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const created = !before?.exists && !!after?.exists;
    const deleted = !!before?.exists && !after?.exists;
    if (!created && !deleted) return;

    const delta = created ? 1 : -1;
    await db.doc(`posts/${event.params.postId}`).set(
      {
        shareCount: FieldValue.increment(delta),
        score: FieldValue.increment(delta),
      },
      { merge: true }
    );
  }
);
