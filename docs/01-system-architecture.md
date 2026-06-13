# 01 · System Architecture

## 1. Architectural goals

| Goal | Implication |
|------|-------------|
| **Fast time-to-MVP** | Lean on managed Firebase services; avoid bespoke infra |
| **Realtime & offline-first** | Firestore listeners + local cache; optimistic UI |
| **Trust boundary discipline** | Money, verification, roles, and AI keys live **server-side only** |
| **Scales to millions of feed reads** | Denormalize, fan-out, cache, and rank pragmatically |
| **Swappable AI/media/payment vendors** | Hide vendors behind Cloud Functions + Remote Config |
| **Compliant monetization** | Native IAP for in-app digital goods; web/Stripe for B2B ads |

## 2. High-level topology

```
┌───────────────────────────────────────────────────────────────────────┐
│                          CLIENTS                                        │
│  Flutter (Android / iOS)            Flutter Web (Admin Panel)           │
│  - Feed, Stories, Chat, Live        - Moderation, verification approvals│
│  - Riverpod + go_router             - Revenue & analytics dashboards    │
└───────▲───────────────▲───────────────────────────▲────────────────────┘
        │ SDKs          │ HTTPS/callable             │ realtime
        │               │                            │
┌───────┴───────────────┴────────────────────────────┴────────────────────┐
│                       FIREBASE PLATFORM                                   │
│                                                                          │
│  Auth ──► custom claims (role, premium, verified)                        │
│  Cloud Firestore  ◄── security rules (firestore.rules)                   │
│  Cloud Storage    ◄── security rules (storage.rules)                     │
│  Cloud Functions (Node/TS) ── trusted compute & webhooks                 │
│  Cloud Messaging (FCM) ── push                                           │
│  App Check ── attestation       Remote Config ── flags/model IDs         │
│  Analytics · Crashlytics · Performance                                   │
└───────▲───────────────────────────────────────────────────────────────┘
        │  (Functions call out / vendors call back via webhooks)
┌───────┴───────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                                   │
│  OpenAI (text + images)      Vertex AI Imagen/Veo (optional)            │
│  Flutterwave / Paystack / Stripe (web)   RevenueCat (mobile subs/IAP)   │
│  Agora/100ms (live streaming)   Algolia (search)                        │
│  Mux/Cloudflare Stream (video transcode/CDN)   Branch (deep links)      │
└───────────────────────────────────────────────────────────────────────┘
```

## 3. Client architecture (Flutter)

The app follows a **feature-first, layered (Clean-ish) architecture**. Full
detail in [09 Flutter Architecture](09-flutter-architecture.md). Summary:

```
Presentation (Widgets/Screens)
        │  watches
Application (Riverpod controllers / StateNotifiers, AsyncValue)
        │  calls
Domain (Entities, use-case logic, repository interfaces)
        │  implemented by
Data (Repositories → Firestore/Storage/Functions datasources, DTO mapping)
```

- **Offline-first:** Firestore persistence enabled; writes are optimistic and
  reconciled by listeners.
- **No business-critical logic on the client.** The client *requests* verification,
  *initiates* payment, *composes* an AI prompt — but the server decides outcomes.
- **App Check** is enforced on Functions and (where supported) Firestore/Storage
  so only genuine app builds can call the backend.

## 4. Backend compute model

Firestore + Storage handle the **CRUD + realtime** path directly from the client
(governed by security rules). **Cloud Functions** own everything that must be
*trusted, secret, or aggregated*:

| Concern | Why it must be server-side |
|---------|----------------------------|
| Payment capture & verification | Never trust the client that money arrived; verify via webhook signatures |
| Granting verified/premium/role | Privilege escalation must be impossible from the client |
| AI proxying (OpenAI/Vertex) | API keys must never ship in the app; enforce quotas & moderation |
| Feed fan-out & FYP ranking | Aggregation/heavy reads; keep clients thin |
| Counters & trending | Atomic, abuse-resistant aggregation |
| Notifications | Authorized senders only; templating + FCM tokens |
| Moderation actions | Enforce admin authorization and audit |

Function trigger types used:
- **HTTPS Callable** — client-invoked actions (start verification, run AI assistant, create ad).
- **HTTPS (raw)** — third-party **webhooks** (Stripe/Flutterwave/Paystack/RevenueCat, Mux, Agora tokens).
- **Firestore triggers** — `onCreate`/`onUpdate`/`onWrite` for fan-out, counters, moderation, search sync.
- **Scheduled (Pub/Sub)** — trending recompute, story expiry sweeps, digest notifications.
- **Auth triggers** — provision user docs on sign-up; cleanup on delete.

See [10 Cloud Functions](10-cloud-functions.md) for the full catalog.

## 5. Core data-flow examples

### 5.1 Posting to the feed
```
User composes post
  → client writes posts/{postId} (rules check author == uid, App Check)
  → onCreate(posts) Function:
       • update authorHandle/counters
       • extract #hashtags → increment hashtags/{tag}
       • fan-out to followers' home feeds (bounded) OR mark for pull-ranking
       • sync post to Algolia
       • enqueue "new post" signals for FYP
```

### 5.2 Verification + payment (trust-critical)
```
User taps "Get Verified"
  → callable startVerification(): create verificationRequests/{id} = pending_payment
  → client opens payment (RevenueCat/IAP on mobile · Flutterwave/Paystack/Stripe + mobile money on web)
  → PROVIDER webhook → Function verifyPayment():
       • validate signature & amount
       • write payments/{id} (server-only)
       • set verificationRequests/{id} = paid → review
  → Admin approves in panel → Function:
       • set users/{uid}.verified = true (server-only field)
       • set custom claim { verified: true }
       • notify user
```
The client can **request** but never **grant** verification. See
[04 User Flows §Verification](04-user-flows.md#3-verification--payment) and
[07 Monetization](07-monetization.md).

### 5.3 AI writing assistant
```
User writes draft + selects "Improve / Rewrite / Generate article"
  → callable aiAssist({ task, text, tone }):
       • App Check + auth + rate-limit + quota (free vs premium)
       • pick model tier by task & plan (mini/standard/flagship via Remote Config)
       • call OpenAI API (key in Secret Manager) — stream long-form
       • moderate output, log usage/cost, return text
```
Keys never touch the device. Premium unlocks higher tiers & higher quotas
([06 Integrations §AI](06-integrations.md#3-ai-services)).

### 5.4 Direct messaging (realtime)
```
Client writes conversations/{cid}/messages/{mid} (rules: sender ∈ members)
  → listeners deliver to other members instantly
  → onCreate(messages) Function: bump conversation.lastMessage, unread counts, push
```

### 5.5 Live streaming
```
Host taps "Go Live"
  → callable createLiveStream(): liveStreams/{id} = live, returns Agora token
  → viewers callable joinLiveStream(): get viewer token, subscribe
  → live chat/reactions via Firestore subcollection or Agora RTM
  → host ends → Function finalizes stream, optional VOD to Mux
```

## 6. Environments & project setup

- **Three Firebase projects:** `myspot-dev`, `myspot-staging`, `myspot-prod`
  (isolation of data, keys, billing). FlutterFire flavors map to each.
- **Secrets** (OpenAI, Stripe, Flutterwave, Paystack, Agora, Algolia admin) in **Cloud
  Secret Manager**, referenced by Functions — never in client or repo.
- **Remote Config** holds feature flags, AI model IDs/tiers, quotas, and
  rollout gates.
- **CI/CD:** GitHub Actions → build/test Flutter, deploy Functions/rules/indexes
  per environment; Fastlane (or Codemagic) for store builds.

## 7. Scaling & cost posture

| Pressure point | Strategy |
|----------------|----------|
| Feed reads (hot path) | Denormalized author snapshots; hybrid fan-out; Algolia/CDN offload |
| Counters (likes/follows) | Distributed counter shards or Function-batched increments |
| Video bandwidth | Offload to Mux/Cloudflare Stream HLS + CDN, not Storage egress |
| Search | Algolia/Typesense, synced by Functions (Firestore is not a search engine) |
| FYP ranking | Start heuristic (cheap); graduate to embeddings + vector match |
| AI cost | Tiered models, per-plan quotas, caching, server-side budgets |
| Abuse/bots | App Check, rate limits, reCAPTCHA on auth, report→moderation loop |

## 8. Key non-obvious decisions (read these)

1. **Firebase Dynamic Links is retired** — referrals/deep-links use **Branch**
   (or AppsFlyer) + native App/Universal Links. Do not design around Dynamic Links.
2. **In-app digital goods must use native IAP** (Apple/Google policy). Verification
   badges and premium subscriptions are sold via **StoreKit/Play Billing (RevenueCat)**
   on mobile; the **advertiser/web portal** uses Flutterwave/Paystack/Stripe. [07](07-monetization.md)
   covers the compliance line in detail.
3. **Firestore is the source of truth, not a search/recommendation engine.**
   Search → Algolia; ranking → dedicated ranking functions/services.
4. **The Founder Journey is a first-class entity**, not a post type bolted on —
   it has its own schema, prompts, and discovery surface ([02](02-firestore-data-model.md)).
