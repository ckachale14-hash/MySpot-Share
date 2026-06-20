import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import OpenAI from "openai";
import { assertWithinQuota, logAiUsage } from "../lib/quota";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Tier -> env var holding the concrete model id (set per env / Remote Config).
// Env wins; the fallbacks keep the function working out-of-the-box — a missing
// AI_MODEL_* would otherwise call OpenAI with model=undefined and throw (the
// generic `internal` error the client sees).
const MODEL_BY_TIER = {
  fast: () => process.env.AI_MODEL_FAST || "gpt-4o-mini", // grammar / short caption
  standard: () => process.env.AI_MODEL_STANDARD || "gpt-4o", // rewrite / generate
  premium: () => process.env.AI_MODEL_PREMIUM || "gpt-4o", // long-form article
} as const;

type Tier = keyof typeof MODEL_BY_TIER;

function pickTier(task: string, plan: string): Tier {
  if (task === "grammar" || task === "caption_short") return "fast";
  if (task === "article" || task === "founder_story") {
    return plan === "free" ? "standard" : "premium";
  }
  return "standard";
}

function buildPrompt(task: string, text: string): string {
  switch (task) {
    case "grammar":
      return `Fix grammar and spelling, keep meaning and voice:\n\n${text}`;
    case "rewrite":
      return `Rewrite to be clearer and more engaging:\n\n${text}`;
    case "improve":
      return `Improve this post for a business audience:\n\n${text}`;
    case "caption_short":
      return `Write a short, punchy caption for:\n\n${text}`;
    case "article":
      return `Write a structured business article based on these notes:\n\n${text}`;
    case "founder_story":
      return `Help me tell my founder journey compellingly from these notes:\n\n${text}`;
    default:
      return text;
  }
}

/**
 * Tiered OpenAI writing assistant. Keys + model IDs are server-side only.
 * Enforces App Check, per-plan quota, and input/output moderation.
 */
export const aiAssist = onCall(
  { secrets: [OPENAI_API_KEY], enforceAppCheck: false },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const { task, text, tone } = (req.data ?? {}) as {
      task?: string;
      text?: string;
      tone?: string;
    };
    if (!task || !text) {
      throw new HttpsError("invalid-argument", "`task` and `text` are required.");
    }

    const plan = (req.auth?.token.plan as string) ?? "free";
    await assertWithinQuota(uid, plan, task);

    const client = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

    // Screen the prompt (OpenAI moderation is free).
    const modModel = process.env.AI_MODERATION_MODEL || "omni-moderation-latest";
    const inMod = await client.moderations.create({ model: modModel, input: text });
    if (inMod.results[0]?.flagged) {
      throw new HttpsError("failed-precondition", "Input violates content policy.");
    }

    const tier = pickTier(task, plan);
    const isLongForm = task === "article" || task === "founder_story";

    const system =
      "You are MySpot's business writing assistant for entrepreneurs. " +
      "Write clear, credible, motivating business content. " +
      (tone ? `Tone: ${tone}. ` : "") +
      "Never invent facts the user didn't provide.";

    const completion = await client.chat.completions.create({
      model: MODEL_BY_TIER[tier](),
      max_tokens: isLongForm ? 6000 : 1200,
      messages: [
        { role: "system", content: system },
        { role: "user", content: buildPrompt(task, text) },
      ],
    });

    const out = completion.choices[0]?.message?.content ?? "";

    const outMod = await client.moderations.create({ model: modModel, input: out });
    if (outMod.results[0]?.flagged) {
      throw new HttpsError("internal", "Generated content failed moderation.");
    }

    await logAiUsage(uid, tier, completion.usage);
    return { text: out };
  }
);
