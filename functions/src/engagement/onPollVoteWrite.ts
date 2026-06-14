import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

/**
 * Maintain a poll's tally as votes are cast, changed, or withdrawn.
 * Vote docs live at posts/{postId}/votes/{uid} = { option: <index> }.
 * Tallies (poll.tally.<index>) and poll.totalVotes are server-only — clients
 * can read but never write them (firestore.rules).
 */
export const onPollVoteWrite = onDocumentWritten(
  "posts/{postId}/votes/{uid}",
  async (event) => {
    const before = event.data?.before.exists
      ? (event.data.before.data() as { option?: number })
      : undefined;
    const after = event.data?.after.exists
      ? (event.data.after.data() as { option?: number })
      : undefined;

    const beforeOpt = typeof before?.option === "number" ? before.option : undefined;
    const afterOpt = typeof after?.option === "number" ? after.option : undefined;
    if (beforeOpt === afterOpt) return; // nothing changed

    const update: Record<string, FieldValue> = {};
    let delta = 0;
    if (beforeOpt !== undefined) {
      update[`poll.tally.${beforeOpt}`] = FieldValue.increment(-1);
      delta -= 1;
    }
    if (afterOpt !== undefined) {
      update[`poll.tally.${afterOpt}`] = FieldValue.increment(1);
      delta += 1;
    }
    if (delta !== 0) update["poll.totalVotes"] = FieldValue.increment(delta);
    if (Object.keys(update).length === 0) return;

    try {
      await db.doc(`posts/${event.params.postId}`).update(update);
    } catch (e) {
      console.error("onPollVoteWrite: tally update failed", e);
    }
  }
);
