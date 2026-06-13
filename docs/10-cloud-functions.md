# 10 · Cloud Functions Catalog

Cloud Functions (**Node 20 / TypeScript**, Firebase Functions v2) are the
trusted backend. They own everything the client must not: money, identity,
ranking, AI keys, fan-out, and notifications. Secrets come from **Secret
Manager**; tunables from **Remote Config**.

```
functions/
├── src/
│   ├── index.ts                 # exports
│   ├── auth/                    # onUserCreate, onUserDelete, setRole
│   ├── feed/                    # onPostCreate (fan-out, hashtags, search, signals)
│   ├── engagement/              # like/comment/follow counters
│   ├── stories/                 # expiry backstop sweep
│   ├── messaging/               # onMessageCreate (lastMessage, unread, push)
│   ├── verification/            # startVerification, approveVerification
│   ├── payments/                # stripeWebhook, razorpayWebhook, revenueCatWebhook
│   ├── ads/                     # submitCampaign, approveAd, meterAdEvent
│   ├── live/                    # createLiveStream, joinLiveStream, endLiveStream
│   ├── ai/                      # aiAssist, generateImage, generateVideo
│   ├── ranking/                 # recomputeScores (scheduled), buildFyp
│   ├── notifications/           # sendNotification helper + fan-out
│   ├── moderation/              # onReportCreate, moderateContent, adminActions
│   └── lib/                     # admin sdk, secrets, remoteConfig, guards
└── package.json
```

---

## Function catalog

### 1. Auth & identity
| Function | Trigger | Does |
|----------|---------|------|
| `onUserCreate` | Auth `onCreate` | provision `users/{uid}` + `private`, default claims `{role:'user'}`, reserve handle, apply referral |
| `onUserDelete` | Auth `onDelete` | GDPR cleanup of user data/media |
| `setUserRole` | Callable (admin) | set `role` claim + mirror + `adminAudit` |

### 2. Feed & engagement
| Function | Trigger | Does |
|----------|---------|------|
| `onPostCreate` | Firestore `posts onCreate` | denormalize author, `postCount++`, parse `#hashtags` → increment `hashtags/{tag}`, hybrid fan-out to followers' `home`, **Algolia** sync, FYP signals |
| `onPostDelete` | `posts onDelete` | decrement counters, remove from search/home |
| `onLikeWrite` | `posts/{id}/likes/{uid} onWrite` | batched `likeCount` update + notify author |
| `onCommentCreate` | `comments onCreate` | `commentCount++`, notify, search |
| `onFollowWrite` | `follows onWrite` | maintain `followerCount`/`followingCount`, notify, fan-out seed |

> Counters use batched/transactional increments (or sharded counters for hot
> docs) to stay atomic and abuse-resistant.

### 3. Stories
| Function | Trigger | Does |
|----------|---------|------|
| `sweepExpiredStories` | Scheduled | backstop delete of expired stories (primary expiry is the **TTL policy** on `expiresAt`) |

### 4. Verification & payments (trust-critical)
| Function | Trigger | Does |
|----------|---------|------|
| `startVerification` | Callable | create `verificationRequests/{id}=pending_payment` (App Check + auth) |
| `stripeWebhook` / `razorpayWebhook` / `revenueCatWebhook` | HTTPS | **verify signature**, idempotency on `providerRef`, append `payments/{id}`, advance verification to `in_review` / grant subscription + claims, notify |
| `approveVerification` | Callable (admin) | set `users/{uid}.verified=true` + claim, `adminAudit`, notify (only from `in_review`) |

### 5. AI proxy
| Function | Trigger | Does |
|----------|---------|------|
| `aiAssist` | Callable | text writing assistant — tiered Claude by task/plan, quota + moderation |
| `generateImage` | Callable | Vertex AI Imagen → Storage → attach to draft (premium) |
| `generateVideo` | Callable | Vertex AI Veo async job → Mux (premium) |

### 6. Advertising
| Function | Trigger | Does |
|----------|---------|------|
| `submitCampaign` | Callable | move draft → `pending_review` after funding verified |
| `approveAd` | Callable (admin) | activate/reject creatives |
| `meterAdEvent` | Callable/HTTPS | record impression/click, decrement `budget.spent`, pause at cap |

### 7. Live
| Function | Trigger | Does |
|----------|---------|------|
| `createLiveStream` | Callable | create `liveStreams/{id}=live`, mint host **Agora token** |
| `joinLiveStream` | Callable | mint viewer token, `viewerCount++` |
| `endLiveStream` | Callable | finalize, optional VOD to Mux |

### 8. Ranking & notifications & moderation
| Function | Trigger | Does |
|----------|---------|------|
| `recomputeScores` | Scheduled | refresh `posts.score` from engagement velocity/recency |
| `buildFyp` | Callable | assemble ranked FYP page (candidates + score + ad insertion) |
| `sendNotification` | (internal) | write `notifications/{id}` + FCM to tokens (respect prefs) |
| `onReportCreate` | `reports onCreate` | enqueue, auto-flag obvious cases |
| `moderateContent` | Callable/trigger | safety checks on UGC/AI output |
| `adminAction` | Callable (admin) | suspend/remove/ban + `adminAudit` |

---

## Representative: `aiAssist` (writing assistant)

Keys and model IDs are **server-side only**. Models are chosen by task & plan and
read from environment/Remote Config — **no model ID is hardcoded**, so upgrading
the underlying Claude model is a config change, not a code change.

```ts
// functions/src/ai/aiAssist.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import Anthropic from "@anthropic-ai/sdk";
import { assertWithinQuota, logAiUsage } from "../lib/quota";
import { moderate } from "../moderation/moderateContent";

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

// Tier → env var holding the concrete model id (set per environment / Remote Config).
// e.g. ANTHROPIC_MODEL_FAST, ANTHROPIC_MODEL_STANDARD, ANTHROPIC_MODEL_PREMIUM
const MODEL_BY_TIER = {
  fast:     () => process.env.ANTHROPIC_MODEL_FAST!,      // grammar / short caption
  standard: () => process.env.ANTHROPIC_MODEL_STANDARD!,  // rewrite / generate post
  premium:  () => process.env.ANTHROPIC_MODEL_PREMIUM!,   // long-form article / journey
};

// Map the requested task + the user's plan to a model tier.
function pickTier(task: string, plan: string): keyof typeof MODEL_BY_TIER {
  if (task === "grammar" || task === "caption_short") return "fast";
  if (task === "article" || task === "founder_story") {
    return plan === "free" ? "standard" : "premium";
  }
  return "standard"; // improve / rewrite / generate
}

export const aiAssist = onCall(
  { secrets: [ANTHROPIC_API_KEY], enforceAppCheck: true },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const { task, text, tone } = req.data as { task: string; text: string; tone?: string };
    if (!task || !text) throw new HttpsError("invalid-argument", "task and text required.");

    const plan = (req.auth?.token.plan as string) ?? "free";
    await assertWithinQuota(uid, plan, task);           // per-plan rate/budget limits
    await moderate(text);                                // screen the prompt

    const client = new Anthropic({ apiKey: ANTHROPIC_API_KEY.value() });
    const tier = pickTier(task, plan);
    const isLongForm = task === "article" || task === "founder_story";

    const system =
      "You are MySpot's business writing assistant for entrepreneurs. " +
      "Write clear, credible, motivating business content. " +
      (tone ? `Tone: ${tone}. ` : "") +
      "Never invent facts the user didn't provide.";

    // Stream long-form generations to avoid request timeouts; collect the final text.
    const stream = client.messages.stream({
      model: MODEL_BY_TIER[tier](),
      max_tokens: isLongForm ? 6000 : 1200,
      system,
      messages: [{ role: "user", content: buildPrompt(task, text) }],
    });
    const message = await stream.finalMessage();

    const out = message.content.find((b) => b.type === "text")?.text ?? "";
    await moderate(out);                                  // screen the output
    await logAiUsage(uid, tier, message.usage);          // cost/usage accounting

    return { text: out };
  }
);

function buildPrompt(task: string, text: string): string {
  switch (task) {
    case "grammar":       return `Fix grammar and spelling, keep meaning and voice:\n\n${text}`;
    case "rewrite":       return `Rewrite to be clearer and more engaging:\n\n${text}`;
    case "improve":       return `Improve this post for a business audience:\n\n${text}`;
    case "caption_short": return `Write a short, punchy caption for:\n\n${text}`;
    case "article":       return `Write a structured business article based on these notes:\n\n${text}`;
    case "founder_story": return `Help me tell my founder journey compellingly from these notes:\n\n${text}`;
    default:              return text;
  }
}
```

Key points:
- `enforceAppCheck: true` blocks non-app callers.
- **Quotas/budgets** per plan (free vs Pro vs Business) prevent cost runaway.
- **Moderation** on both prompt and output.
- **Streaming** for long-form (per SDK guidance for large `max_tokens`).
- **Usage logging** feeds billing/abuse analytics.
- Premium plans get the higher-quality tier and larger quotas — the monetization
  lever from [07](07-monetization.md).

---

## Representative: payment webhook (verification grant)

```ts
// functions/src/payments/stripeWebhook.ts  (sketch)
export const stripeWebhook = onRequest({ secrets: [STRIPE_SECRET, STRIPE_WH] }, async (req, res) => {
  const event = stripe.webhooks.constructEvent(           // ★ verify signature
    req.rawBody, req.headers["stripe-signature"]!, STRIPE_WH.value());

  if (event.type === "checkout.session.completed") {
    const s = event.data.object;
    const { userId, purpose, relatedId } = s.metadata!;

    await db.runTransaction(async (tx) => {
      const payRef = db.doc(`payments/${event.id}`);       // idempotency by event id
      if ((await tx.get(payRef)).exists) return;           // already processed
      tx.set(payRef, {                                     // append-only ledger
        userId, provider: "stripe", providerRef: s.payment_intent,
        purpose, amount: s.amount_total, currency: s.currency,
        status: "succeeded", metadata: { relatedId, eventId: event.id },
        createdAt: FieldValue.serverTimestamp(),
      });
      if (purpose === "verification") {
        tx.update(db.doc(`verificationRequests/${relatedId}`),
          { status: "in_review", paymentId: event.id });   // ★ only NOW eligible for review
      }
    });
    await notifyUser(userId, "payment_succeeded", { purpose });
  }
  res.sendStatus(200);
});
```

This is why the client can never fake verification/premium: entitlements flow
**only** from a signature-verified webhook writing the server-only ledger and
flags.

---

## Operational guidance

- **Idempotency** on every webhook (key on provider event/charge id).
- **Least privilege:** callables verify `auth` + `role` claims; admin functions
  re-check `role == 'admin'`.
- **Secrets** via Secret Manager (`defineSecret`), never env-committed.
- **Cold starts:** keep heavy deps lazy; set min instances on hot webhooks/AI.
- **Observability:** structured logs + alerts on webhook failures, AI error
  rates, and budget thresholds.
- **Testing:** Functions unit tests + emulator integration tests in CI alongside
  rules tests.
