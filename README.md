# MySpot — Business Networking, Entrepreneurship & Motivation Platform

A modern cross-platform (Android + iOS) social network focused entirely on
**entrepreneurship, business growth, motivation, and professional networking** —
combining the best of LinkedIn, Instagram, TikTok, and Facebook, purpose-built
for entrepreneurs, business owners, customers, investors, and professionals.

> **The core mission:** make it effortless and rewarding for every entrepreneur
> to share *how they started* — their capital, challenges, mistakes, lessons,
> milestones, and wins — so the next generation can learn from real-world
> experience. The "Founder Journey" is a first-class object in this platform,
> not an afterthought.

This repository contains the **complete system architecture, data model,
security model, user flows, screen designs, integration plan, monetization
strategy, and development roadmap** authored by a senior product/Flutter/Firebase
architecture review. It is the blueprint the engineering team builds from.

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

**Config artifacts** (real, ready to adapt):
- [`firestore.rules`](firestore.rules) — production-shaped security rules ✅ *unit-tested*
- [`storage.rules`](storage.rules) — Storage security rules
- [`firestore.indexes.json`](firestore.indexes.json) — composite indexes for the feed/FYP/search queries

**Phase P0 scaffold (runnable):** [`app/`](app) (Flutter — auth → onboarding → 5-tab
shell), [`functions/`](functions) (TypeScript — auth provisioning + OpenAI AI proxy,
`tsc` clean), [`test/`](test) (Firestore rules tests, passing), CI in
[`.github/workflows`](.github/workflows). **Start here → [`SETUP.md`](SETUP.md).**

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
| AI — image | **Vertex AI Imagen** (Firebase AI Logic) | Promotional graphics, social content |
| AI — video | **Vertex AI Veo** / Runway (premium-gated) | Short promo & motivational clips |
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

## Repository layout (target)

```
MySpot-Share/
├── README.md
├── docs/                      # this architecture set
├── firestore.rules            # security rules (DB)
├── storage.rules              # security rules (media)
├── firestore.indexes.json     # composite indexes
├── firebase.json              # Firebase project config (added at init)
├── app/                       # Flutter application (added in P0)
│   ├── lib/
│   │   ├── core/              # config, theme, router, di, utils
│   │   ├── data/              # repositories, datasources, dtos
│   │   ├── domain/            # entities, value objects
│   │   ├── features/          # feature-first modules (auth, feed, chat, ...)
│   │   └── main.dart
│   └── test/
├── functions/                 # Cloud Functions (TypeScript)
│   ├── src/
│   └── package.json
└── admin/                     # Flutter Web admin panel (or shared with app/)
```

The Flutter app, Functions, and admin panel are scaffolded in **Phase P0** of the
roadmap. This repo currently holds the **architecture and contracts** that those
implementations must satisfy.

---

## How to use this blueprint

1. Read [01 System Architecture](docs/01-system-architecture.md) end-to-end.
2. Stand up a Firebase project; deploy [`firestore.rules`](firestore.rules),
   [`storage.rules`](storage.rules), and [`firestore.indexes.json`](firestore.indexes.json).
3. Scaffold the Flutter app per [09 Flutter Architecture](docs/09-flutter-architecture.md).
4. Implement features in roadmap order, using [02 Data Model](docs/02-firestore-data-model.md)
   and [10 Cloud Functions](docs/10-cloud-functions.md) as the contracts.
5. Wire monetization per [07](docs/07-monetization.md) **early** — store review and
   payment compliance are long-pole items.
