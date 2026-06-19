import { onSchedule } from "firebase-functions/v2/scheduler";
import { getStorage } from "firebase-admin/storage";
import { db } from "../lib/admin";

/**
 * Backstop reaper for expired stories. A Firestore TTL policy on `expiresAt` is
 * the primary expiry, but TTL deletes only the top-level document — it leaves
 * the `views` subcollection and the Storage media behind. This sweep finishes
 * the job: it removes the doc (and its subcollections) and the story's media
 * blobs. Client queries already filter on `expiresAt`, so this is purely
 * cleanup, never a correctness dependency.
 */

const BATCH = 100; // stories reaped per run

export const sweepExpiredStories = onSchedule("every 60 minutes", async () => {
  const snap = await db
    .collection("stories")
    .where("expiresAt", "<=", new Date())
    .limit(BATCH)
    .get();
  if (snap.empty) return;

  const bucket = getStorage().bucket();

  await Promise.all(
    snap.docs.map(async (doc) => {
      const authorId = doc.get("authorId") as string | undefined;

      // Best-effort media cleanup. Story media lives under a per-story prefix
      // (see storage.rules: users/{uid}/stories/{storyId}/...).
      if (authorId) {
        try {
          await bucket.deleteFiles({
            prefix: `users/${authorId}/stories/${doc.id}/`,
          });
        } catch (e) {
          console.error(`sweepExpiredStories: media cleanup failed for ${doc.id}`, e);
        }
      }

      // recursiveDelete removes the story doc and its `views` subcollection.
      try {
        await db.recursiveDelete(doc.ref);
      } catch (e) {
        console.error(`sweepExpiredStories: doc delete failed for ${doc.id}`, e);
      }
    })
  );
});
