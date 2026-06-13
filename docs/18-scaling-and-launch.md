# 18 · Scaling & Launch Playbook (toward millions of users)

Enterprise recommendations to take MySpot from MVP to a platform that supports
millions — with an **Africa-first** lens (Android, mobile data, mobile money,
data-residency).

## 1. Firestore at scale (the data layer)

- **Model for queries; denormalize read-hot data.** Feeds must render without
  joins (author/like-state on the post).
- **Avoid hot documents.** No single doc taking thousands of writes/sec. Use
  **distributed counter shards** or **batched/aggregated counters in Functions**
  for likes/followers/trending.
- **Don't fan-out to mega-accounts.** Hybrid: push to inboxes for normal accounts,
  **pull + rank** for accounts with huge follower counts.
- **Bounded queries + pagination** everywhere; composite indexes for every feed/
  discovery/admin query ([`firestore.indexes.json`](../firestore.indexes.json)).
- **TTL policies** for ephemera (stories) to auto-reclaim storage.
- **BigQuery export** for analytics — never run analytical scans on Firestore.

## 2. Media & bandwidth (critical in Africa)

- **Offload video to Mux/Cloudflare Stream** (HLS, adaptive bitrate, CDN) — not
  Storage egress.
- **CDN with African edge PoPs** (e.g. Cloudflare) for images/media to cut
  latency and egress.
- **Aggressive client image compression**, responsive image variants, lazy video,
  and a **"data saver" mode** (lower-res media, autoplay off) — respects users'
  data costs and lowers your egress bill.
- **Offline-first**: Firestore persistence, cached images, optimistic UI — the app
  must feel good on flaky 3G.

## 3. Search & recommendations

- **Algolia/Typesense** for search (Firestore can't); sync via Functions.
- FYP: heuristic → **Vertex embeddings + vector search** as scale and data grow
  ([12](12-recommendation-engine.md)). When ranking/search become the bottleneck,
  graduate them to dedicated services rather than overloading Firestore.

## 4. Regions & data residency

- Choose the **Firestore/Storage location** closest to your primary market to
  minimize latency from Africa (evaluate available regions; African data-residency
  is emerging — pick the best current option and design to migrate).
- Plan for **data-protection compliance per market**: Nigeria **NDPR**, Kenya
  **DPA**, South Africa **POPIA**, and **GDPR** for global users — data export &
  deletion (already a Function), consent, retention limits, and KYC handling.

## 5. Reliability & operations

- **Three environments** (dev/staging/prod), **IaC** (rules/indexes/Functions in
  git), **CI/CD** (`.github/workflows/ci.yml`) with rules tests + analyze + build
  gating every deploy.
- **SLOs & monitoring:** Crashlytics, Performance, Cloud Monitoring; alert on
  Function error rates, webhook failures, latency, and budgets.
- **Incident response:** on-call, runbooks, status page; idempotent webhooks so
  retries are safe.
- **Gradual rollout:** Remote Config feature flags + canary cohorts; never
  big-bang a risky change to all users.
- **Load testing** before major launches (feed, live, messaging hot paths).

## 6. Security & abuse at scale

- **App Check** enforced on Functions/Firestore/Storage (bots inflate cost *and*
  poison FYP/ad metrics).
- **Per-user & global rate limits/quotas** (AI, OTP, messaging, live, posting).
- **WAF/Cloud Armor** in front of public HTTPS Functions (webhooks, ad serving).
- **Secrets in Secret Manager**, least-privilege service accounts, rotation.
- **Fraud controls** on payments (webhook verification, idempotency, velocity
  checks), and **fake-engagement detection** to protect ranking & advertisers.
- Continuous **trust & safety**: layered moderation + report SLAs ([16](16-admin-panel.md)).

## 7. Africa-first product hardening

- **Android-first** QA across low-end devices; small APK/AAB; Play Billing flows.
- **Localization** (languages per market) and locally-relevant content/onboarding.
- **Mobile-money payments** front-and-center; minimize SMS-OTP dependence (cost +
  deliverability) by favoring social/email auth and session reuse.
- **Accessibility** (contrast, text scaling, RTL-ready) and **low-literacy-friendly**
  flows where relevant.

## 8. Avoiding lock-in (plan the exits early)

Firebase is the right **accelerator**, but design so the heaviest workloads can
move if economics demand it at very large scale:

- Keep **business logic in Functions** behind clean repository interfaces (the
  app doesn't hard-couple to Firestore specifics).
- **Analytics already in BigQuery**; **search already external** (Algolia);
  **media already external** (Mux/CDN). These are the workloads most likely to
  outgrow Firebase first.
- If/when Firestore read costs or query limits bind, consider a **managed
  Postgres** (e.g. Cloud SQL/AlloyDB) for relational/heavy-query domains and a
  dedicated feed/ranking service — migrate incrementally, domain by domain.

## 9. Launch sequence

1. **Closed beta** (single city/market): dogfood, fix retention, validate
   payments + moderation.
2. **Soft launch** (one country): turn on referrals, ambassadors, telco/partner
   pilots; watch unit economics and cost dashboards.
3. **Scale within region**: paid acquisition only after D7/D30 retention is
   healthy; expand markets with localized content & payments.
4. **Global expansion**: add Stripe-heavy markets, more languages, region
   strategy; revisit data residency and infra placement.

## 10. Team to operate at scale

Beyond the MVP squad ([08 §Team](08-roadmap.md#team-shape-lean-senior-squad)):
backend/SRE for reliability & cost, data/ML for FYP, **trust & safety** ops
(moderation), finance/ops for multi-currency reconciliation & payouts, growth/
partnerships (telcos, incubators), and market/community managers per country.

---

### One-page scale checklist
- [ ] Denormalized feed, distributed counters, no mega-account fan-out
- [ ] All media on CDN/Mux; image compression + data-saver mode
- [ ] Search on Algolia/Typesense; analytics on BigQuery
- [ ] App Check + rate limits + WAF + fraud controls everywhere
- [ ] Budgets/alerts + weekly cost review (reads, egress, AI, live, SMS)
- [ ] Remote Config flags + canary rollout; rules tests in CI
- [ ] Data-protection compliance per market; data export/delete live
- [ ] Mobile-money payments; minimal SMS-OTP; Android-first QA
