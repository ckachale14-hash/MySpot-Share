import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { notify, Actor } from "../lib/notifications";

/** New comment: bump commentCount + score and notify the post author. */
export const onCommentCreate = onDocumentCreated(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const comment = snap.data();
    const postId = event.params.postId;

    const postRef = db.doc(`posts/${postId}`);
    await postRef.set(
      {
        commentCount: FieldValue.increment(1),
        score: FieldValue.increment(2),
      },
      { merge: true }
    );

    const postSnap = await postRef.get();
    if (!postSnap.exists) return;
    const authorId = postSnap.get("authorId") as string;

    const actor = (comment.author ?? { uid: comment.authorId }) as Actor;
    await notify({
      toUid: authorId,
      type: "comment",
      actor,
      postId,
      text: (comment.text as string | undefined)?.slice(0, 120),
    });
  }
);

/** Reverse the counters when a comment is deleted. */
export const onCommentDelete = onDocumentDeleted(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    if (!event.data) return;
    await db.doc(`posts/${event.params.postId}`).set(
      {
        commentCount: FieldValue.increment(-1),
        score: FieldValue.increment(-2),
      },
      { merge: true }
    );
  }
);
