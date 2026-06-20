import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import OpenAI from "openai";
import { db } from "../lib/admin";
import { assertWithinQuota } from "../lib/quota";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const AI_VIDEO_API_KEY = defineSecret("AI_VIDEO_API_KEY");

/**
 * Premium AI video generation (async job). Validates + moderates + quota-gates,
 * creates a `videoJobs/{id}` record, and submits to the configured video provider.
 * Completion is handled by the pollVideoJobs scheduled function.
 *
 * Provider wiring is generic (env-configured endpoint) so you can point it at
 * OpenAI video / Runway / Pika / Veo without code changes — see .env.example.
 */
export const requestVideo = onCall(
  { secrets: [OPENAI_API_KEY, AI_VIDEO_API_KEY], enforceAppCheck: false },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const plan = (req.auth?.token.plan as string) ?? "free";
    if (plan === "free") {
      throw new HttpsError("failed-precondition", "AI video is a Premium feature.");
    }
    const prompt = String(req.data?.prompt ?? "").trim();
    if (!prompt) throw new HttpsError("invalid-argument", "A prompt is required.");

    await assertWithinQuota(uid, plan, "video");

    // Moderate the prompt.
    const client = new OpenAI({ apiKey: OPENAI_API_KEY.value() });
    const mod = await client.moderations.create({
      model: process.env.AI_MODERATION_MODEL as string,
      input: prompt,
    });
    if (mod.results[0]?.flagged) {
      throw new HttpsError("failed-precondition", "Prompt violates content policy.");
    }

    const ref = db.collection("videoJobs").doc();
    await ref.set({
      userId: uid,
      prompt,
      status: "queued",
      videoUrl: null,
      providerJobId: null,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Submit to the configured provider (generic integration point).
    const url = process.env.AI_VIDEO_API_URL;
    if (url) {
      try {
        const resp = await fetch(url, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${AI_VIDEO_API_KEY.value()}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ model: process.env.AI_VIDEO_MODEL, prompt }),
        });
        const json = (await resp.json()) as { id?: string };
        if (resp.ok && json.id) {
          await ref.update({ status: "processing", providerJobId: json.id });
        } else {
          await ref.update({ status: "failed" });
        }
      } catch (e) {
        console.error("requestVideo: provider submit failed", e);
        await ref.update({ status: "failed" });
      }
    }

    return { jobId: ref.id };
  }
);
