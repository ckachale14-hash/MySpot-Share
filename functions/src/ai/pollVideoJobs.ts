import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { sendPush } from "../lib/notifications";

const AI_VIDEO_API_KEY = defineSecret("AI_VIDEO_API_KEY");

/**
 * Poll the video provider for jobs still processing; on completion store the
 * result URL and notify the user. Generic provider status endpoint (env), so it
 * adapts to whichever video API you wire up. (Production: re-host the result to
 * Storage/Mux rather than keeping a provider URL that may expire.)
 */
export const pollVideoJobs = onSchedule(
  { schedule: "every 2 minutes", secrets: [AI_VIDEO_API_KEY] },
  async () => {
    const statusUrl = process.env.AI_VIDEO_STATUS_URL;
    if (!statusUrl) return;

    const snap = await db
      .collection("videoJobs")
      .where("status", "==", "processing")
      .limit(20)
      .get();

    for (const doc of snap.docs) {
      const providerJobId = doc.get("providerJobId") as string | undefined;
      if (!providerJobId) continue;
      try {
        const resp = await fetch(`${statusUrl}/${providerJobId}`, {
          headers: { Authorization: `Bearer ${AI_VIDEO_API_KEY.value()}` },
        });
        const json = (await resp.json()) as { status?: string; url?: string };
        if (json.status === "completed" && json.url) {
          await doc.ref.update({
            status: "ready",
            videoUrl: json.url,
            completedAt: FieldValue.serverTimestamp(),
          });
          await sendPush(
            doc.get("userId") as string,
            "Your AI video is ready 🎬",
            "Tap to view it in MySpot.",
            { type: "video_ready", jobId: doc.id }
          );
        } else if (json.status === "failed") {
          await doc.ref.update({ status: "failed" });
        }
      } catch (e) {
        console.error("pollVideoJobs: status check failed", e);
        // Leave as processing; retry on the next tick.
      }
    }
  }
);
