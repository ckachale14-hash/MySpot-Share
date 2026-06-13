import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { notify, Actor } from "../lib/notifications";

/**
 * Follow edge at follows/{followerId_followingId}. Maintains follower/following
 * counts and notifies the followed user on a new follow.
 */
export const onFollowWrite = onDocumentWritten("follows/{edgeId}", async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  const created = !before?.exists && !!after?.exists;
  const deleted = !!before?.exists && !after?.exists;
  if (!created && !deleted) return;

  const data = (after?.exists ? after.data() : before?.data()) ?? {};
  const followerId = data.followerId as string;
  const followingId = data.followingId as string;
  if (!followerId || !followingId) return;

  const delta = created ? 1 : -1;
  const batch = db.batch();
  batch.set(
    db.doc(`users/${followerId}`),
    { followingCount: FieldValue.increment(delta) },
    { merge: true }
  );
  batch.set(
    db.doc(`users/${followingId}`),
    { followerCount: FieldValue.increment(delta) },
    { merge: true }
  );
  await batch.commit();

  if (!created) return;

  const followerSnap = await db.doc(`users/${followerId}`).get();
  const follower = followerSnap.data() ?? {};
  const actor: Actor = {
    uid: followerId,
    handle: follower.handle,
    displayName: follower.displayName,
    photoUrl: follower.photoUrl,
  };
  await notify({ toUid: followingId, type: "follow", actor });
});
