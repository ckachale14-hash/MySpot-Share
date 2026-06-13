import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { notify, Actor } from "../lib/notifications";

/**
 * Like edge at posts/{postId}/likes/{likeUid}. Maintains likeCount + score on
 * the post, records an interest signal, and notifies the author on a new like.
 */
export const onLikeWrite = onDocumentWritten(
  "posts/{postId}/likes/{likeUid}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const created = !before?.exists && !!after?.exists;
    const deleted = !!before?.exists && !after?.exists;
    if (!created && !deleted) return;

    const postId = event.params.postId;
    const likeUid = event.params.likeUid;
    const delta = created ? 1 : -1;

    const postRef = db.doc(`posts/${postId}`);
    await postRef.set(
      {
        likeCount: FieldValue.increment(delta),
        score: FieldValue.increment(delta),
      },
      { merge: true }
    );

    if (!created) return;

    const postSnap = await postRef.get();
    if (!postSnap.exists) return;
    const post = postSnap.data() as Record<string, unknown>;

    // Interest signal: bump the liker's affinity for this post's categories.
    const tags = Array.isArray(post.hashtags) ? (post.hashtags as string[]) : [];
    if (tags.length) {
      const inc: Record<string, FirebaseFirestore.FieldValue> = {};
      for (const tag of tags.slice(0, 10)) inc[`categories.${tag}`] = FieldValue.increment(1);
      await db
        .doc(`users/${likeUid}/interests/summary`)
        .set({ ...inc, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    }

    // Notify the post author.
    const likerSnap = await db.doc(`users/${likeUid}`).get();
    const liker = likerSnap.data() ?? {};
    const actor: Actor = {
      uid: likeUid,
      handle: liker.handle,
      displayName: liker.displayName,
      photoUrl: liker.photoUrl,
    };
    await notify({
      toUid: post.authorId as string,
      type: "like",
      actor,
      postId,
    });
  }
);
