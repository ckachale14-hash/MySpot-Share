# 06 · Integrations & External APIs

Every third-party vendor sits **behind Cloud Functions** (for secrets/trust) or a
well-isolated client SDK. Vendor choices and model IDs are injected via
**Secret Manager** and **Remote Config** so they can change without a new build.

---

## 1. Payments (Africa-first)

Two payment surfaces with **different rules** — this distinction is the single
most important compliance decision in the app (see [07 Monetization](07-monetization.md)).
Because MySpot launches in Africa, **mobile money is a first-class rail**, not an
afterthought, and Android is the dominant platform.

| Surface | Provider | Used for | Why |
|---------|----------|----------|-----|
| **In-app (mobile)** | **RevenueCat** → Play Billing (Android) / StoreKit (iOS) | Premium subscriptions, verification badge, AI credits | Google/Apple require their billing for **in-app digital goods/services** |
| **Web / advertiser portal** | **Flutterwave** + **Paystack** (cards, bank, USSD, **mobile money**: M-Pesa, MTN MoMo, Airtel) + **Stripe** (global cards) | Ad spend, featured listings, B2B billing, **web purchase of premium/verification via mobile money** | Pan-African coverage + the web rail lets mobile-money users pay outside the app store |

> **Mobile-money nuance (important):** many target users pay with M-Pesa/MoMo, not
> a card on file in the Play Store. Google Play *does* require Play Billing for
> in-app digital goods, but purchases made **outside** the app (on the MySpot
> website/PWA) may use Flutterwave/Paystack mobile money. The recommended pattern:
> offer **both** — Play Billing in-app for convenience, and a **web checkout with
> mobile money** for everyone else — and validate per-market against current Play
> policy. Advertising/featured-listing spend (B2B) always goes through the **web
> portal** on Flutterwave/Paystack/Stripe.

### Integration shape (always webhook-verified)
```
Client initiates purchase
  → provider hosted checkout / native sheet / mobile-money STK push
  → provider WEBHOOK ─► Cloud Function:
        • verify signature (Stripe-Signature / verif-hash / Paystack sig / RC auth)
        • idempotency on providerRef
        • write payments/{id} (server-only ledger, with currency)
        • grant entitlement (subscriptions/{uid}, verified flag, credits) + claim
        • notify user
```
- **Never** trust a client "payment succeeded" callback to grant entitlements —
  always the webhook. (Mobile-money flows are async: the STK push completes
  out-of-band, so the webhook is the *only* source of truth.)
- **RevenueCat** unifies Play/StoreKit receipts and emits a single webhook +
  entitlement model; its webhook is the source of truth for mobile subs.
- **Flutterwave/Paystack** webhooks confirm card/bank/USSD/mobile-money charges;
  verify the signature/hash and re-query the provider's verify endpoint before granting.
- Store **multi-currency** amounts (KES, NGN, GHS, ZAR, USD…) in the ledger.
- Secrets (`STRIPE_SECRET`, `STRIPE_WEBHOOK_SECRET`, `FLUTTERWAVE_SECRET`,
  `FLUTTERWAVE_WEBHOOK_HASH`, `PAYSTACK_SECRET`, `REVENUECAT_WEBHOOK_AUTH`) live
  in Secret Manager.

Flutter packages: `purchases_flutter` (RevenueCat), Flutterwave/Paystack mobile
SDKs or hosted checkout (WebView) for the web/portal flows, `flutter_stripe`
where global cards are needed.

---

## 2. Media pipeline

| Asset | Path | Processing |
|-------|------|------------|
| Images | Firebase Storage | Client compresses; a Storage-trigger Function can generate thumbnails/variants |
| Short video | Storage → **Mux** / **Cloudflare Stream** | Function uploads/ingests to Mux for **HLS transcoding + CDN + adaptive bitrate**; store `playbackId` on the post |
| Live VOD | Agora recording → Mux | optional recorded replay |

> **Don't stream video bytes straight from Storage at scale** — egress cost and no
> adaptive bitrate. Offload playback to Mux/Cloudflare Stream HLS behind a CDN.
> For the MVP a direct-from-Storage short clip + thumbnail is acceptable; wire
> Mux before video usage grows.

Image handling: `image_picker`, `cached_network_image`, client-side compression;
video: `video_player`/`chewie` for playback, `mux_player`/HLS for transcoded.

---

## 3. AI services

All AI runs **server-side** through Cloud Functions. The OpenAI/Vertex keys
never ship in the client. Quotas differ by plan (free vs Pro vs Business).

### 3.1 Writing assistant (text) — **OpenAI**, tiered

Pick the model **by task and plan** to balance quality vs cost. Exact model IDs
are set in **Remote Config / env** (`AI_MODEL_FAST` / `_STANDARD` / `_PREMIUM`)
— not hardcoded — so upgrades are config-only.

| Task | Tier | Rationale |
|------|------|-----------|
| Grammar/spelling fix, short caption, quick tone tweak | **OpenAI mini** | Cheapest & fastest; high volume |
| Improve/rewrite a post, generate captions, marketing snippets | **OpenAI standard** | Best balance of quality & cost |
| Long-form **business articles**, **founder-story drafting**, premium marketing copy | **OpenAI flagship** | Highest quality; premium-gated |

Implementation notes:
- Use the official **`openai`** Node SDK in Functions (Node/TS).
- **Stream** long-form generations (`stream: true`) so long articles don't hit
  request timeouts; return progressively to the client.
- Default `max_tokens` generously for articles (e.g. ~4–8k); small for grammar fixes.
- Enforce **per-plan rate limits & monthly token budgets**; log usage/cost per
  user for billing and abuse detection.
- **Moderate** input & output (OpenAI's moderation endpoint is free) before returning.
- Representative callable in [10 Cloud Functions §aiAssist](10-cloud-functions.md#5-ai-proxy).

> The tiers map to OpenAI's small / standard / flagship model families. Keep the
> precise model IDs in Remote Config and review them periodically as OpenAI ships
> newer models — the function code never needs to change.

### 3.2 Image generation — **Vertex AI Imagen**
Promotional images, business graphics, social content. Called from a Function
(`generateImage`), result stored to Storage, attached to the draft post/ad.
Integrates cleanly with the Firebase/GCP project (Firebase AI Logic / Vertex AI
in Firebase). Premium-gated; per-plan quotas.

### 3.3 Video generation — **Vertex AI Veo** (or Runway/Pika)
Short promo/motivational/ad clips. Highest cost → **premium-only**, low quotas,
async job pattern (enqueue → poll/callback → store to Mux). Treat as a
later-phase, clearly-gated feature.

### 3.4 Recommendations (FYP)
- **P1:** heuristic ranking function (recency + engagement + affinity + interest
  match) — see [04 §FYP](04-user-flows.md#4-personalized-fyp-for-you-page).
- **P4:** Vertex AI **text embeddings** for content/user vectors + vector search
  (Vertex Matching Engine) for semantic similarity and better cold-start.

---

## 4. Search — **Algolia** (or Typesense)

Firestore cannot do typo-tolerant, full-text, federated search. A Function syncs
`users`, `businesses`, `posts`, `founderJourneys`, and `hashtags` into Algolia
indices on write; the client queries Algolia directly with a **search-only API
key** (scoped, safe to ship). Supports the required filters (people, businesses,
posts, videos, industries, hashtags) and advanced facets.

Self-hosted alternative: **Typesense** (cheaper at scale, more ops).

---

## 5. Live streaming — **Agora** (or 100ms / LiveKit)

- **Token security:** channel tokens are minted **server-side** (`createLiveStream`
  / `joinLiveStream` callables) using the Agora app certificate in Secret Manager
  — clients never hold the certificate.
- **Live chat/reactions:** Firestore subcollection for MVP; Agora **RTM** for
  scale.
- **Recording → VOD:** Agora cloud recording to storage → Mux for replay.
- Flutter: `agora_rtc_engine`.

Alternatives: **100ms** and **LiveKit** (LiveKit is open-source/self-hostable).

---

## 6. Deep links & referrals — **Branch** (NOT Dynamic Links)

> ⚠️ **Firebase Dynamic Links is retired.** Do not build referrals/deep links on
> it. Use **Branch.io** (or AppsFlyer/Adjust) for deferred deep linking +
> install attribution, layered on native **Universal Links (iOS)** and **App
> Links (Android)**.

- Shareable links (posts, profiles, businesses, journeys, invites) carry context
  (`type`, `id`, `referralCode`).
- **Deferred deep linking:** a new user who installs from an invite lands on the
  right screen *and* the referral is attributed post-install.
- Branch webhook/SDK → Function writes `referrals/{code}` signups/rewards.
- Invite channels: WhatsApp, Facebook, Instagram, Email, SMS, copyable link
  (`share_plus`).

---

## 7. Push notifications — **FCM**

- Tokens stored in `users/{uid}/private.fcmTokens` (deduped; pruned on send
  failure).
- Functions send templated pushes for likes/comments/follows/mentions/messages/
  verification/ads/live/system; payloads deep-link via go_router.
- Respect per-user notification preferences (Settings).
- Flutter: `firebase_messaging`, `flutter_local_notifications`.

---

## 8. Auth providers

Firebase Auth: **Email/Password, Phone (OTP), Google, Apple** (Apple is mandatory
if you offer other social logins on iOS). 2FA is a future enhancement
(`firebase_auth`, `google_sign_in`, `sign_in_with_apple`).

---

## 9. Observability & ops

| Concern | Tool |
|---------|------|
| Crashes | Crashlytics |
| Product analytics / funnels | Firebase Analytics (+ optional Amplitude/Mixpanel) |
| Performance | Firebase Performance Monitoring |
| Function logs/alerts | Cloud Logging + alerting on error rates / webhook failures |
| Cost guardrails | Budgets + alerts on Functions/Storage/AI/egress |

---

## 10. Secrets & config summary

| Where | Holds |
|-------|-------|
| **Secret Manager** | OpenAI key, Stripe/Flutterwave/Paystack keys + webhook secrets, RevenueCat auth, Agora certificate, Algolia **admin** key, Mux/Branch keys |
| **Remote Config** | feature flags, AI model IDs/tiers, AI quotas, FYP weights, rollout gates |
| **Client (safe)** | Firebase config, Algolia **search-only** key, Branch key, public Stripe/Flutterwave/Paystack publishable keys |

**Nothing private is ever committed to this repo or shipped in the app binary.**
