# 08 · Development Roadmap

A pragmatic, ship-incrementally plan. Each phase ends with something usable and
testable. Durations assume a **small senior team** (see §Team); treat them as
relative sizing, not commitments.

---

## Phase overview

| Phase | Theme | Outcome | Rough size |
|-------|-------|---------|-----------|
| **P0** | Foundation | Project scaffolding, auth, profiles, CI, rules deployed | 3–4 wks |
| **P1** | Social core | Posts, feed/FYP v1, stories, follow, comments, journeys, search, notifications | 5–7 wks |
| **P2** | Monetization | Verification (paid), premium (IAP), payment ledger, admin v1 | 4–6 wks |
| **P3** | Engagement & AI | Messaging, live streaming, AI writing assistant, advertising | 6–8 wks |
| **P4** | Scale & polish | FYP ML, image/video AI, analytics depth, perf, hardening, launch | 5–7 wks |

> MVP = **P0–P3** (everything the brief lists). P4 strengthens and scales.

---

## P0 — Foundation

**Goal:** a signed, themed app talking to a secured Firebase backend.

- Firebase projects (dev/staging/prod); FlutterFire flavors; App Check.
- Flutter scaffold per [09](09-flutter-architecture.md): core (theme, router,
  DI, env), Riverpod, go_router, design system + widget catalog.
- **Auth:** email, phone, Google, Apple; Auth-trigger Function provisions
  `users/{uid}` + `private` + default claims; handle uniqueness.
- **Profiles:** view/edit user profile; account type & industry/interests;
  business profile create/edit.
- Deploy `firestore.rules`, `storage.rules`, `firestore.indexes.json`.
- **CI/CD:** GitHub Actions (analyze/test/build), rules-unit-tests, Functions
  deploy; Crashlytics/Analytics wired.

**Exit:** users sign up, complete profiles, see a themed empty home; rules tested
in CI.

---

## P1 — Social core

**Goal:** the network is alive — people post, follow, discover, get notified.

- **Posts** (text/image/video/article/poll); composer; media upload pipeline;
  `onCreate` fan-out, counters, hashtag indexing.
- **Feed/FYP v1** (heuristic ranking function) + stories bar.
- **Stories/Status** with 24h TTL policy + viewer.
- **Founder Journeys** ⭐ guided editor + Journeys discovery.
- **Engagement:** like/comment/share/save; follow/unfollow; "People You May
  Know", "New Users", Trending.
- **Search** via Algolia sync (people/businesses/posts/journeys/hashtags).
- **Notifications** (in-app center + FCM).

**Exit:** a usable social product; internal/beta dogfooding begins.

---

## P2 — Monetization foundations

**Goal:** the business model works end-to-end and safely.

- **Payment ledger + webhook verification** (Flutterwave/Paystack/Stripe/RevenueCat) — build
  first; it underpins everything.
- **Verification flow** (KYC upload → pay → review → grant) with the
  payment-before-review state machine.
- **Premium subscriptions** via RevenueCat (IAP) + entitlement claims.
- **Admin panel v1** (Flutter Web): users, verification queue (signed-URL doc
  review), reports/moderation, revenue view, audit log.

**Exit:** real payments grant real entitlements; admins can verify & moderate.

---

## P3 — Engagement & AI (completes MVP)

**Goal:** the differentiating, sticky, revenue-expanding features.

- **Messaging:** 1:1 + group, media/files, read receipts, push.
- **Live streaming:** Agora host/viewer, server token minting, live chat,
  viewer counts, optional VOD.
- **AI writing assistant:** OpenAI-tiered (mini/standard/flagship) via Functions;
  improve/rewrite/grammar/caption/article + "write my founder story"; per-plan
  quotas & moderation.
- **Advertising:** web Ads Manager portal (Flutterwave/Paystack/Stripe), creatives, review,
  feed/story ad serving, metrics & budget caps.
- **Invite/referrals:** Branch deferred deep links + attribution.

**Exit:** all brief MVP features shipped; closed beta → soft launch.

---

## P4 — Scale, ML & launch

**Goal:** make it fast, smart, and ready for volume.

- **FYP ML:** Vertex embeddings + vector match; engagement-trained ranking;
  experimentation framework (Remote Config A/Bs).
- **AI image (Imagen)** + **video (Veo)** generation, premium-gated.
- **Video at scale:** Mux/Cloudflare Stream HLS + CDN.
- **Analytics depth:** retention/cohorts, advertiser audience insights.
- **Hardening:** load testing, cost guardrails, distributed counters where hot,
  security review, accessibility & localization passes.
- **Launch:** store optimization, marketing site, support flows.

---

## Team shape (lean senior squad)

| Role | Focus |
|------|-------|
| Flutter lead + 1–2 Flutter devs | client, design system, features |
| Backend/Functions engineer | payments, AI, fan-out, moderation, search sync |
| Product designer | design system, flows, premium UX |
| QA / release | test, store submissions, rules tests |
| (Part-time) data/ML | FYP ranking → embeddings (P4) |
| Product/PM + founder | scope, monetization, partnerships |

A focused team can reach **MVP (P0–P3) in roughly 4–6 months**; P4 follows.

---

## Cross-cutting workstreams (every phase)

- **Security & privacy:** rules tests, App Check, PII handling, KYC storage,
  GDPR/CCPA data export & delete.
- **Compliance:** app-store payment policy ([07 §4](07-monetization.md#4-️-app-store-compliance-do-not-skip)),
  ad disclosure, content policy.
- **Observability:** Crashlytics/Analytics/Performance + Function alerting.
- **Cost control:** budgets/alerts on Functions, Storage egress, AI, video.
- **Content moderation:** report→review loop from P1; automated safety on AI/UGC.

---

## Top risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Store rejection over payments | IAP for in-app digital goods; web portal for ads; legal review early |
| Firestore cost blowups (counters/feeds) | denormalize, batch counters, hybrid fan-out, CDN/Algolia offload |
| AI cost runaway | tiered models, per-plan quotas, server budgets, caching |
| Video bandwidth cost | Mux/Cloudflare Stream + CDN, not Storage egress |
| FYP cold start | capture interests at signup; heuristic before ML |
| Deep-link regression | Branch (Dynamic Links is retired) |
| Moderation/trust at scale | verification + App Check + report loop + automated safety |
