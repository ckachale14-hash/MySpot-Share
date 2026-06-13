import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getStorage } from "firebase-admin/storage";
import * as crypto from "crypto";
import OpenAI from "openai";
import { assertWithinQuota } from "../lib/quota";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

/**
 * Premium AI image generation for promotional graphics. Generates with OpenAI,
 * stores to the user's Storage path with a permanent download token, and returns
 * a URL the client can attach to a post/ad.
 */
export const generateImage = onCall(
  { secrets: [OPENAI_API_KEY], enforceAppCheck: true },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const plan = (req.auth?.token.plan as string) ?? "free";
    if (plan === "free") {
      throw new HttpsError("failed-precondition", "AI image generation is a Premium feature.");
    }
    const prompt = String(req.data?.prompt ?? "").trim();
    if (!prompt) throw new HttpsError("invalid-argument", "A prompt is required.");

    await assertWithinQuota(uid, plan, "image");

    const client = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

    const mod = await client.moderations.create({
      model: process.env.AI_MODERATION_MODEL as string,
      input: prompt,
    });
    if (mod.results[0]?.flagged) {
      throw new HttpsError("failed-precondition", "Prompt violates content policy.");
    }

    const result = await client.images.generate({
      model: process.env.AI_IMAGE_MODEL as string,
      prompt,
      size: "1024x1024",
    });

    const data = result.data?.[0];
    let buffer: Buffer;
    if (data?.b64_json) {
      buffer = Buffer.from(data.b64_json, "base64");
    } else if (data?.url) {
      const resp = await fetch(data.url);
      buffer = Buffer.from(await resp.arrayBuffer());
    } else {
      throw new HttpsError("internal", "No image returned.");
    }

    const token = crypto.randomUUID();
    const path = `users/${uid}/posts/ai_${Date.now()}.png`;
    const bucket = getStorage().bucket();
    await bucket.file(path).save(buffer, {
      contentType: "image/png",
      metadata: { metadata: { firebaseStorageDownloadTokens: token } },
    });
    const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;

    return { url };
  }
);
