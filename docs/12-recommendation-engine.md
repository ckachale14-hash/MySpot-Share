# 12 · Recommendation Engine (FYP)

The For-You feed is the growth engine. It must be **good on day one** (heuristic,
cheap) and **improve continuously** (ML later), all behind a Cloud Function so the
algorithm changes without app releases.

## 1. Pipeline

```
Request FYP page (buildFyp callable / paginated)
  1. CANDIDATE GENERATION  — assemble a pool (~300–500) from multiple sources
  2. FEATURE HYDRATION     — attach signals for user × candidate
  3. SCORING               — rank by a weighted score (Remote Config weights)
  4. POLICY / DIVERSITY    — dedupe, freshness, author diversity, ad insertion
  5. SERVE + LOG           — return page; record impressions for feedback
```

## 2. Candidate sources

| Source | Rationale |
|--------|-----------|
| **Followed authors' recent posts** | strong affinity |
| **Interest/industry match** | `users/{uid}/interests` × post `hashtags`/category |
| **Trending** | `hashtags` by `score`; high-velocity posts |
| **Fresh / new users** | gives newcomers a chance (also a product promise) |
| **Founder Journeys** | inject signature content the platform wants seen |
| **Eligible sponsored** | approved active ads, inserted at fixed cadence |
| **Collaborative signal (later)** | "users like you also engaged with…" |

## 3. Signals (features)

Per-user (from `users/{uid}/interests`, updated by engagement triggers):
interest/industry vector, followed authors, historical category engagement,
search history, active hours, locale/location (opt-in), device/data-mode.

Per-post: author affinity, engagement counts & **velocity** (engagement/time
since post), recency, media type, category/hashtags, quality/safety score,
author reputation (verified, follower base), prior exposure to this user.

## 4. Scoring (MVP heuristic)

```
score(post | user) =
     w_affinity   · affinity(author, user)          // follow + past engagement
   + w_interest   · interestMatch(post, user)        // category/hashtag overlap
   + w_velocity   · engagementVelocity(post)         // likes+comments+shares / age
   + w_recency    · recencyDecay(post.createdAt)     // exponential time decay
   + w_quality    · qualityScore(post)               // completeness, media, safety
   + w_journey    · isFounderJourney(post)           // small boost for signature content
   − w_seen       · seenPenalty(post, user)          // demote already-shown
   − w_fatigue    · authorFatigue(author, user)      // limit same-author runs
```

- **Weights live in Remote Config** → tune/A-B test without releases.
- **Recency decay** keeps the feed fresh; **velocity** surfaces rising content
  early (good for new creators).
- `score` is also persisted on `posts.score` (recomputed by `recomputeScores`)
  so trending/discovery queries are cheap.

## 5. Diversity, freshness & exploration

- **Author diversity:** cap consecutive posts per author; spread the feed.
- **Exploration (ε-greedy / bandit):** reserve a slice (~10–15%) for
  lower-confidence candidates so the model keeps learning and new creators get
  discovered — prevents rich-get-richer collapse.
- **Ad cadence:** insert at most 1 sponsored item per N organic (Remote Config),
  always labeled **Sponsored**.
- **Negative feedback:** "not interested", hide, report → strong demotion + signal.

## 6. Cold start

- Capture **industry + interests at signup** (onboarding) → immediate seed.
- New users see a blend of trending + popular journeys in their industry + new
  creators, until behavioral signal accrues.
- New posts get a **velocity probe** (shown to a small audience) before broad
  distribution — earns reach by early engagement.

## 7. Feedback loop

```
Impression / dwell / like / comment / share / save / follow / hide / report
  → engagement-trigger Functions update users/{uid}/interests (affinities, categories)
  → recomputeScores refreshes post velocity/score on a schedule
  → next FYP page reflects updated signals
```

## 8. Evolution path (to ML at scale)

1. **P1:** heuristic scoring (above) — cheap, transparent, tunable.
2. **P4:** **embeddings** — Vertex AI text embeddings for posts & a user-interest
   vector; **vector similarity** (Vertex Vector Search / Matching Engine) for
   semantic candidate generation and better cold start.
3. **Later:** a learned ranker (gradient-boosted or two-tower retrieval +
   ranking model) trained on logged engagement; serve via Vertex AI; keep the
   heuristic as fallback and for explainability.

## 9. Infrastructure & performance

- **Hybrid fan-out:** push recent posts from followed/affinity authors into
  `users/{uid}/home` for cheap reads; **pull + rank** the broader candidate pool
  on request. Avoid fanning to millions of inboxes for mega-accounts (pull those).
- **Precompute** trending and per-user candidate sets on a schedule; **rank**
  at request time over a bounded pool to keep latency low and cost predictable.
- **Cache** FYP pages briefly per user; paginate with a stable cursor.
- **Cost control:** bounded candidate pools, scheduled (not per-request) heavy
  precompute, and ranking weights in Remote Config (no compute to change them).

## 10. Abuse resistance

App Check + rate limits + engagement-quality checks (detect like/follow rings)
so fake engagement can't game ranking or ad metrics. Removed/flagged content is
excluded by `removed`/safety score.

## 11. Metrics to watch

CTR, dwell time, like/comment/share/save rate, **follow-through from FYP**,
session length, creator-reach distribution (Gini — is reach too concentrated?),
journey-creation lift, and negative-feedback rate.
