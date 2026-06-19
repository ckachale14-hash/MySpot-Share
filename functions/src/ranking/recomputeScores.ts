import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../lib/admin";

/**
 * Periodic ranking refresh. Engagement counters (`likeCount`, `commentCount`, …)
 * are maintained live by the engagement triggers, but the `score` field they
 * also bump only ever grows — so "top posts" and "trending" tags drift toward
 * all-time popularity. This job re-bases `score` from engagement weighted by a
 * recency decay, so the score-ranked feed (`posts` by `visibility,score`) and
 * the trending query (`hashtags` by `score`) reflect what's hot *now*.
 *
 * It is a backstop, not the source of immediate feedback: live increments still
 * nudge scores between runs; this pass applies the decay.
 */

// Only recent posts are ranking candidates; older ones age out of "hot".
const POST_WINDOW_DAYS = 14;
const POST_HALF_LIFE_HOURS = 24; // engagement weight halves every 24h
const POST_PAGE = 400;
const POST_MAX_PAGES = 25; // safety cap (~10k posts/run)

// Hashtag scores decay multiplicatively each run; active tags are kept aloft by
// the +1 that onPostCreate adds per new post using the tag.
const HASHTAG_DECAY = 0.85;
const HASHTAG_FLOOR = 0.5; // below this, snap to 0
const HASHTAG_PAGE = 400;

/** Weighted engagement for a post from its denormalized counters. */
function engagementOf(d: FirebaseFirestore.DocumentData): number {
  const likes = Number(d.likeCount ?? 0);
  const comments = Number(d.commentCount ?? 0);
  const shares = Number(d.shareCount ?? 0);
  const saves = Number(d.saveCount ?? 0);
  const views = Number(d.viewCount ?? 0);
  return likes + 2 * comments + 3 * shares + 2 * saves + 0.05 * views;
}

async function decayPostScores(): Promise<void> {
  const cutoff = new Date(Date.now() - POST_WINDOW_DAYS * 24 * 3600 * 1000);
  const now = Date.now();
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  for (let page = 0; page < POST_MAX_PAGES; page++) {
    let q = db
      .collection("posts")
      .where("createdAt", ">=", cutoff)
      .orderBy("createdAt", "asc")
      .limit(POST_PAGE);
    if (last) q = q.startAfter(last);

    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    let writes = 0;
    for (const doc of snap.docs) {
      const d = doc.data();
      const createdAt = d.createdAt as FirebaseFirestore.Timestamp | undefined;
      const ageHours = createdAt ? (now - createdAt.toMillis()) / 3600000 : 0;
      const decay = Math.pow(0.5, ageHours / POST_HALF_LIFE_HOURS);
      const next = Math.round(engagementOf(d) * decay);
      // Skip no-op writes to keep this cheap on quiet posts.
      if (next !== Math.round(Number(d.score ?? 0))) {
        batch.update(doc.ref, { score: next });
        writes++;
      }
    }
    if (writes) await batch.commit();

    last = snap.docs[snap.docs.length - 1];
    if (snap.size < POST_PAGE) break;
  }
}

async function decayHashtagScores(): Promise<void> {
  let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;

  for (;;) {
    let q = db.collection("hashtags").orderBy("__name__").limit(HASHTAG_PAGE);
    if (last) q = q.startAfter(last);

    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    let writes = 0;
    for (const doc of snap.docs) {
      const score = Number(doc.get("score") ?? 0);
      if (score <= 0) continue;
      const decayed = score * HASHTAG_DECAY;
      const next = decayed < HASHTAG_FLOOR ? 0 : Math.round(decayed * 100) / 100;
      batch.update(doc.ref, { score: next });
      writes++;
    }
    if (writes) await batch.commit();

    last = snap.docs[snap.docs.length - 1];
    if (snap.size < HASHTAG_PAGE) break;
  }
}

export const recomputeScores = onSchedule("every 60 minutes", async () => {
  await decayPostScores();
  await decayHashtagScores();
});
