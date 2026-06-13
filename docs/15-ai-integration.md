# 15 · AI Integration

All AI runs **server-side through Cloud Functions** — API keys never ship in the
app, every call is App-Check-gated, quota/credit-metered, and moderated. Provider
**model IDs live in Remote Config / env** so they can be upgraded without a release.
The text/image stack is **OpenAI**; video uses OpenAI (where available) or a
specialized provider, all behind the same env-config pattern.

```
App ──callable──► Cloud Function ──► provider (OpenAI / Vertex / video API)
                      │  App Check · auth · credits/quota · moderation
                      └──► Storage (generated media) · usage log · ledger
```

## 1. AI Writing Assistant (text — OpenAI, tiered)

Tasks: improve, rewrite, grammar fix, generate caption/article, marketing copy,
and **"write my founder story"** from notes. Model tier is chosen by task × plan
(`AI_MODEL_FAST/STANDARD/PREMIUM`), streamed for long-form. Full implementation:
[`functions/src/ai/aiAssist.ts`](../functions/src/ai/aiAssist.ts) and
[10 §aiAssist](10-cloud-functions.md#5-ai-proxy).

## 2. AI Image Generation

Promotional images, business graphics, social content.
```
callable generateImage({ prompt, size, style })
  • App Check + auth + credit check (image costs > text)
  • moderate prompt → call OpenAI Images API
  • moderate result (SafeSearch / image moderation)
  • store to users/{uid}/posts/... or ads/... → return URL + attach to draft
```
Premium-gated; consumes more **AI credits** than text. Async-safe (show progress).

## 3. AI Video Generation

Short promo/motivational/ad clips — the **most expensive** action, so
**premium-only**, low quotas, high credit cost, **asynchronous job** pattern:
```
callable requestVideo({ prompt, durationSec }) → enqueue job (jobs/{id}=queued)
  → worker/poller calls video provider (OpenAI video where available, or
    Runway/Pika/Veo via env-config) → on completion: transcode to HLS (Mux),
    write playbackId, notify user (FCM)
```
Treat as a later-phase, clearly-gated feature; never block a request thread on it.

## 4. Content Moderation (safety)

| Surface | Mechanism |
|---------|-----------|
| AI prompts & outputs (text) | OpenAI **moderation** endpoint (free) — block before returning |
| AI/user images | image safety classifier (Cloud Vision SafeSearch or provider moderation) |
| User posts/comments/stories | async `moderateContent` on create (text + image), auto-flag/quarantine high-risk |
| Live chat | rate-limit + keyword/classifier filters + host/mod tools |
| Human-in-the-loop | `reports/{id}` queue → moderator review in admin panel |

Moderation is **layered**: automated pre-filters + community reports + human
review. High-confidence violations are auto-removed (`removed` flag); ambiguous
ones are queued. See [16 Admin Panel](16-admin-panel.md).

## 5. Feed Recommendation (AI-assisted)

The FYP ranker starts heuristic and graduates to **Vertex AI embeddings + vector
search** for semantic candidate generation and cold-start — full design in
[12 Recommendation Engine](12-recommendation-engine.md).

## 6. AI Credits & cost control

- Each AI action **decrements a server-only credit balance** (atomic, in the
  function) priced to cover model cost + margin (text cheap → video expensive).
- Plans include a monthly allowance; users buy **top-up credit packs**
  ([07 Monetization](07-monetization.md)).
- **Guardrails:** per-plan daily rate limits, monthly token/credit budgets,
  per-user and global spend caps, response caching for repeatable prompts, and
  usage logging (`aiUsageLog`) for billing/abuse analytics.
- Prefer **cheaper tiers by default**; reserve flagship models for premium
  long-form. Pick the cheapest model that meets quality for each task.

## 7. Safety, abuse & privacy

- App Check + auth on every AI callable; rate limits prevent scripted abuse.
- Don't send unnecessary PII to providers; review provider data-retention terms.
- Log prompts/outputs minimally and with care (they may contain user business
  data); apply retention limits.
- Clearly label AI-generated media where appropriate.

## 8. Configuration

| Key | Where |
|-----|-------|
| `OPENAI_API_KEY` (+ any video provider key) | Secret Manager |
| `AI_MODEL_FAST/STANDARD/PREMIUM`, `AI_MODERATION_MODEL`, video model id | Remote Config / `functions/.env` |
| credit prices, per-plan quotas, feature flags | Remote Config |
