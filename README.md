# MySpot Share — Business Networking, Entrepreneurship & Motivation Platform

A modern cross-platform (Android · iOS · Web) social network focused entirely on
**entrepreneurship, business growth, motivation, and professional networking** —
combining the best of LinkedIn, Instagram, TikTok, and Facebook, purpose-built
for entrepreneurs, business owners, customers, investors, and professionals.

> **The core mission:** make it effortless and rewarding for every entrepreneur
> to share *how they started* — their capital, challenges, mistakes, lessons,
> milestones, and wins — so the next generation can learn from real-world
> experience. The "Founder Journey" is a first-class object in this platform,
> not an afterthought.

This repository contains **both the architecture blueprint and a complete,
working implementation** — a Flutter app (Android · iOS · Web), a TypeScript
Cloud Functions backend, security rules, brand identity, legal docs, a store
listing kit, and demo seed data. Every change is compile-verified and CI-green.

---

## Project status

**Implemented & verified** — `flutter analyze` clean · `flutter build web`
compiles · `flutter test` **8/8** · functions `tsc` clean · **26 Firestore rules
tests** passing (all in CI):

- **App** — 64 screens across 20 feature areas: auth (email · Google · Apple ·
  phone OTP), onboarding, paginated For-You feed + posts (text/image/**poll**/
  **article**), stories, **Founder Journeys**, discover/search, direct & **group**
  messaging, live streaming, business directory + reviews, notifications with
  **deep-linking**, **block**/report, settings (notification prefs, account
  deletion), monetization (premium + paid verification — Paystack/Flutterwave on
  web, **RevenueCat IAP** on mobile), AI compose/image, ads manager, in-app admin.
- **Backend** — 31 Cloud Functions: auth provisioning, counters, notifications,
  billing webhooks, AI proxy, live tokens, moderation, **GDPR account-deletion
  cleanup**, poll tallies.
- **Brand** — logo → palette → Material 3 theme, app icons + web favicon, feature
  graphic ([docs/brand/BRAND.md](docs/brand/BRAND.md)).
- **Legal** — Privacy, Terms, Community Guidelines, Ad Policy drafts
  ([docs/legal/](docs/legal)).
- **Launch** — go-live runbook, deploy scripts, store listing kit, demo seed data,
  Android signing config, web hosting (Firebase + Vercel).

**Needs your accounts** (the runtime gate — see **[docs/GO-LIVE.md](docs/GO-LIVE.md)**):
create the Firebase project (`flutterfire configure`), set secrets, deploy the
backend, host the legal pages, capture screenshots, and submit to the stores.

---

## Documentation index

| # | Document | What's inside |
|---|----------|---------------|
| 00 | **This README** | Vision, stack, MVP scope, repo layout |
| 01 | [System Architecture](docs/01-system-architecture.md) | High-level architecture, layers, client/Firebase/3rd-party topology, data flow |
| 02 | [Firestore Data Model](docs/02-firestore-data-model.md) | Every collection, document schema, relationships, denormalization & counters |
| 03 | [Security Rules](docs/03-security-rules.md) | Firestore + Storage rule design, trust boundaries, custom claims |
| 04 | [User Flows](docs/04-user-flows.md) | Auth, verification+payment, posting, FYP, messaging, live, ads, moderation |
| 05 | [Screens & Navigation](docs/05-screens-and-navigation.md) | Screen inventory, navigation graph, design system |
| 06 | [Integrations & APIs](docs/06-integrations.md) | Payments, AI (OpenAI/Vertex), live streaming, search, push, deep links |
| 07 | [Monetization Strategy](docs/07-monetization.md) | Revenue streams, pricing, store-policy compliance, payout flows |
| 08 | [Development Roadmap](docs/08-roadmap.md) | Phased plan, milestones, team shape, estimates, KPIs |
| 09 | [Flutter App Architecture](docs/09-flutter-architecture.md) | Folder structure, state management, packages, conventions, sample code |
| 10 | [Cloud Functions Catalog](docs/10-cloud-functions.md) | Server-side functions: payments, verification, FYP fan-out, AI proxy, notifications |
| 11 | [Product Strategy](docs/11-product-strategy.md) | Vision, competitive moat, personas, growth & user-acquisition (Africa-first) |
| 12 | [Recommendation Engine](docs/12-recommendation-engine.md) | FYP pipeline, scoring formula, cold-start, exploration, ML evolution |
| 13 | [Live Streaming](docs/13-live-streaming.md) | Host/viewer/co-host, token security, chat/reactions, recording, replay, scale |
| 14 | [Messaging](docs/14-messaging.md) | WhatsApp-like DMs/groups, media, read receipts, presence, scale |
| 15 | [AI Integration](docs/15-ai-integration.md) | Writing, image, video, moderation, recommendations, credits & guardrails |
| 16 | [Admin Panel](docs/16-admin-panel.md) | Web dashboard: users, verification, ads, revenue, analytics, moderation |
| 17 | [Firebase Cost Estimates](docs/17-firebase-cost-estimates.md) | Cost drivers, model, ranges at 10K/100K/1M MAU, mitigations, guardrails |
| 18 | [Scaling & Launch](docs/18-scaling-and-launch.md) | Enterprise scale playbook, regions/compliance, abuse, launch sequence |

**Build, launch & brand docs:**

| Document | What's inside |
|----------|---------------|
| [Architecture Diagram](docs/architecture-diagram.md) | System map (client ↔ Firebase ↔ external) with the trust boundary |
| [Go-Live Runbook](docs/GO-LIVE.md) | Ordered checklist: project → secrets → deploy → web/stores |
| [Deploy on Vercel](docs/deploy-vercel.md) | Web preview via Vercel (Flutter build + env vars) |
| [Brand & Color Guide](docs/brand/BRAND.md) | Logo, palette, accessibility, Flutter tokens |
| [Privacy](docs/legal/PRIVACY.md) · [Terms](docs/legal/TERMS.md) · [Community Guidelines](docs/legal/COMMUNITY_GUIDELINES.md) · [Ad Policy](docs/legal/AD_POLICY.md) | Legal drafts (for review) |
| [Store Listing Kit](docs/store/LISTING.md) | Copy, keywords, screenshot plan, data-safety answers |

**Config artifacts** (real, ready to adapt):
- [`firestore.rules`](firestore.rules) — production-shaped security rules ✅ *unit-tested*
- [`storage.rules`](storage.rules) — Storage security rules
- [`firestore.indexes.json`](firestore.indexes.json) — composite indexes for the feed/FYP/search queries

**Runnable app + backend:** [`app/`](app) (Flutter) and [`functions/`](functions)
(TypeScript, `tsc` clean), [`test/`](test) (Firestore rules tests — **26 passing**),
CI in [`.github/workflows`](.github/workflows). **Start here →
[`docs/GO-LIVE.md`](docs/GO-LIVE.md)** (runbook) and [`SETUP.md`](SETUP.md) (detail).
All entitlements (money, identity, ranking) are granted **server-side only** — the
client can request, never grant.

---

## Technology stack (decisions, not options)

| Layer | Choice | Why |
|-------|--------|-----|
| Mobile client | **Flutter (stable), Dart 3** | Single codebase, native performance, rich UI for a feed-heavy app |
| State management | **Riverpod** (+ `riverpod_generator`) | Compile-safe, testable, scales past Provider; Bloc is a viable swap |
| Routing | **go_router** | Declarative deep-link-friendly navigation |
| Backend | **Firebase** | Managed auth, realtime DB, storage, serverless, push — fastest path to MVP |
| Database | **Cloud Firestore** | Realtime, offline, scales horizontally; complemented by search/rec services |
| Serverless | **Cloud Functions (Node 20 / TypeScript)** | Trusted compute for payments, AI, fan-out, moderation |
| Media | **Firebase Storage** + **Mux/Cloudflare Stream** (video) | Storage for images; managed HLS transcoding for video at scale |
| Push | **Firebase Cloud Messaging** | Cross-platform notifications |
| Anti-abuse | **Firebase App Check** + reCAPTCHA/DeviceCheck | Block scripted/abusive clients |
| Search | **Algolia** (or Typesense) | Firestore can't do full-text/typo-tolerant search |
| Payments (web/B2B) | **Flutterwave** + **Paystack** + **Stripe** | Pan-African cards/bank/USSD + **mobile money** (M-Pesa, MoMo, Airtel); global cards |
| Payments (in-app) | **RevenueCat** + StoreKit/Play Billing | Store-policy-compliant subscriptions/verification on mobile |
| AI — text | **OpenAI** (tiered: mini → standard → flagship) | Writing assistant, captions, articles, marketing copy |
| AI — image | **OpenAI images** | Promotional graphics, social content |
| AI — video | **Generic provider adapter** (OpenAI/Runway/Veo, premium-gated) | Short promo & motivational clips — `AI_VIDEO_*` env |
| Live streaming | **Agora** (or 100ms/LiveKit) | Low-latency broadcast + live chat/reactions |
| Deep links / referrals | **Branch** (or AppsFlyer) + App/Universal Links | ⚠️ Firebase Dynamic Links is retired — do **not** use it |
| Admin panel | **Flutter Web** on Firebase Hosting | Reuse models/code; gated by `admin` custom claim |
| Observability | **Crashlytics + Analytics + Performance** | Stability, funnels, perf |

> **Note on AI model IDs:** exact OpenAI/Vertex model identifiers are kept out of
> source and injected via **Remote Config / environment variables** (see
> [docs/06](docs/06-integrations.md) and [docs/10](docs/10-cloud-functions.md)).
> This lets you upgrade models without shipping a new build. The recommended
> OpenAI tiers (a cheap "mini" → a "standard" → a "flagship" for long-form) are
> described in those docs.

---

## MVP scope (Version 1)

Authentication · Profiles · Business profiles · Verification (with payment) ·
Posts · Stories/Status · Likes & comments · FYP feed · Messaging · Live
streaming · Advertising · AI writing assistant · Invite friends · Notifications ·
Admin dashboard.

See the [roadmap](docs/08-roadmap.md) for how this is sequenced into shippable
phases (P0 foundation → P1 social core → P2 monetization → P3 AI/live → P4 scale).

---

## Repository layout

```
MySpot-Share/
├── README.md
├── SETUP.md                   # local setup detail
├── firebase.json · .firebaserc · firestore.rules · storage.rules
├── firestore.indexes.json · database.rules.json
├── docs/                      # architecture set (01–18) + …
│   ├── architecture-diagram.md · GO-LIVE.md · deploy-vercel.md
│   ├── brand/                 # BRAND.md, logo, palette, icons, feature graphic
│   ├── legal/                 # PRIVACY · TERMS · COMMUNITY_GUIDELINES · AD_POLICY
│   └── store/                 # LISTING.md (store kit)
├── app/                       # Flutter application (Android · iOS · Web)
│   ├── lib/{core,data,domain,features}/ + main.dart
│   ├── android/ · ios/ · web/
│   └── test/
├── functions/                 # Cloud Functions (TypeScript, 31 functions)
├── test/                      # Firestore rules tests (26 passing)
├── seed/                      # idempotent demo/seed data (emulator-verified)
└── scripts/                   # preflight · deploy · deploy-web · vercel-build
```

The admin panel is **in-app** (screens gated by the `admin`/`moderator` claim), not
a separate target. Anything `flutterfire`/CLI-generated (`firebase_options.dart`
real values, `google-services.json`, `key.properties`, keystores) is gitignored.

---

## Build & ship

1. **Run it now:** `cd app && flutter run -d chrome` (or a device). For populated
   screens, seed demo data — see [`seed/`](seed).
2. **Verify:** `scripts/preflight.sh` (functions build + analyze + test + rules).
3. **Go live:** follow **[docs/GO-LIVE.md](docs/GO-LIVE.md)** — create the Firebase
   project (`flutterfire configure`), set secrets, `scripts/deploy.sh dev`, then
   `scripts/deploy-web.sh dev` (web) or [Vercel](docs/deploy-vercel.md).
4. **Ship:** signing + store listings per GO-LIVE Phase 8 and
   [the listing kit](docs/store/LISTING.md).

New to the codebase? Read [01 System Architecture](docs/01-system-architecture.md)
and the [architecture diagram](docs/architecture-diagram.md), then
[09 Flutter Architecture](docs/09-flutter-architecture.md).
