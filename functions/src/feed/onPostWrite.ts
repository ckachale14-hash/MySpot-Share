import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { notify, Actor } from "../lib/notifications";

const TAG_RE = /^[a-z0-9_]{1,50}$/;

function cleanTags(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return Array.from(
    new Set(
      raw
        .map((t) => String(t).toLowerCase().replace(/^#/, "").trim())
        .filter((t) => TAG_RE.test(t))
    )
  ).slice(0, 30);
}

/** Maintain author postCount, hashtag trending counters, and mention notifications. */
export const onPostCreate = onDocumentCreated("posts/{postId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const post = snap.data();
  const authorId = post.authorId as string;

  const batch = db.batch();
  batch.update(db.doc(`users/${authorId}`), {
    postCount: FieldValue.increment(1),
  });
  for (const tag of cleanTags(post.hashtags)) {
    batch.set(
      db.doc(`hashtags/${tag}`),
      {
        tag,
        postCount: FieldValue.increment(1),
        score: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  await batch.commit();

  // Notify mentioned users (client supplies resolved uids in post.mentions).
  const mentions = Array.isArray(post.mentions) ? (post.mentions as string[]) : [];
  const actor = (post.author ?? { uid: authorId }) as Actor;
  await Promise.all(
    mentions
      .filter((uid) => uid && uid !== authorId)
      .slice(0, 20)
      .map((uid) =>
        notify({ toUid: uid, type: "mention", actor, postId: event.params.postId })
      )
  );
});

/** Reverse the counters when a post is removed. */
export const onPostDelete = onDocumentDeleted("posts/{postId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const post = snap.data();
  const authorId = post.authorId as string;

  const batch = db.batch();
  batch.update(db.doc(`users/${authorId}`), {
    postCount: FieldValue.increment(-1),
  });
  for (const tag of cleanTags(post.hashtags)) {
    batch.set(
      db.doc(`hashtags/${tag}`),
      { postCount: FieldValue.increment(-1), updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  }
  await batch.commit();
});
