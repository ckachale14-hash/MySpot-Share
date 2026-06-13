# 02 · Firestore Data Model

Firestore is a document database — model for **the queries you run**, not for
normalization. The guiding principles here:

- **Denormalize read-hot data** (author name/avatar/verified onto each post) so
  feed rendering needs no joins.
- **Counters are denormalized fields** updated by Cloud Functions, never summed
  on read.
- **Sensitive fields are isolated** into locked subdocuments or server-only fields.
- **Membership/edges** (likes, follows, conversation members) are their own
  documents so rules and queries stay simple.
- **Server-only fields** (`verified`, `premium`, `role`, all counters, payment
  state) are writable **only** by Functions (Admin SDK bypasses rules). The
  client may read them but never write them — enforced in [`firestore.rules`](../firestore.rules).

Legend: 🔒 = server-only (client read, never write) · ⚡ = denormalized/counter ·
↗ = denormalized snapshot copy.

---

## Collection map

```
users/{uid}
  users/{uid}/private/{profile}          🔒 email, phone, customerIds, fcmTokens
  users/{uid}/notifications/{notifId}
  users/{uid}/home/{postId}              home-feed fan-out (pull view)
  users/{uid}/interests/{signalDoc}      FYP signals (categories, affinities)
businesses/{businessId}
posts/{postId}
  posts/{postId}/comments/{commentId}
  posts/{postId}/likes/{uid}             like edge (membership)
founderJourneys/{journeyId}              ⭐ first-class "how I started" stories
stories/{storyId}                        24h ephemeral (TTL on expiresAt)
  stories/{storyId}/views/{uid}
follows/{followerUid_followingUid}       edge doc
conversations/{conversationId}
  conversations/{conversationId}/messages/{messageId}
verificationRequests/{requestId}         🔒 state machine
payments/{paymentId}                     🔒 immutable ledger
subscriptions/{uid}                      🔒 premium entitlement
adCampaigns/{campaignId}
  ads/{adId}                             creatives under a campaign
liveStreams/{streamId}
  liveStreams/{streamId}/chat/{msgId}
reports/{reportId}                       moderation queue
hashtags/{tag}                           ⚡ trending counters
referrals/{code}                         attribution
adminAudit/{eventId}                     🔒 admin action log
counters/{shardedDoc}                    distributed counters (optional)
```

---

## `users/{uid}`

The public-facing profile. `uid` = Firebase Auth UID.

| Field | Type | Notes |
|-------|------|-------|
| `uid` | string | mirror of doc id |
| `handle` | string | unique `@username`; reserve via `handles/{handle}` lookup doc |
| `displayName` | string | |
| `bio` | string | |
| `photoUrl` | string | profile picture (Storage URL) |
| `coverUrl` | string | cover photo |
| `accountType` | enum | `personal` \| `business_owner` \| `creator` \| `investor` |
| `industry` | string | category tag (drives FYP & "People You May Know") |
| `location` | map | `{ geohash, city, country }` (optional, opt-in) |
| `links` | map | `{ website, linkedin, instagram, x, youtube }` |
| `verified` 🔒 | bool | blue tick — set only after approved+paid verification |
| `premium` 🔒 | bool | premium entitlement mirror of `subscriptions/{uid}` |
| `role` 🔒 | enum | `user` \| `moderator` \| `admin` (also mirrored to custom claims) |
| `followerCount` ⚡ | int | |
| `followingCount` ⚡ | int | |
| `postCount` ⚡ | int | |
| `searchTerms` | array<string> | lowercased prefixes for cheap in-app search (Algolia is primary) |
| `createdAt` | timestamp | |
| `lastActiveAt` | timestamp | drives "New Users" & presence |
| `isNewUser` ⚡ | bool | true for first N days → powers "New Users Discovery" |

### `users/{uid}/private/{profile}` 🔒
PII and tokens, readable **only** by the owner, writable **only** by Functions.

| Field | Type | Notes |
|-------|------|-------|
| `email` | string | |
| `phone` | string | |
| `stripeCustomerId` | string | |
| `paystackCustomerCode` | string | |
| `flutterwaveRef` | string | mobile-money / card customer ref |
| `revenueCatId` | string | |
| `fcmTokens` | array<string> | push targets (deduped, pruned on send failure) |
| `referredBy` | string | referral code used at signup |
| `twoFactorEnabled` | bool | future |

---

## `businesses/{businessId}`

A user may own multiple businesses (business directory entries).

| Field | Type | Notes |
|-------|------|-------|
| `ownerId` | string | `users/{uid}` |
| `name` | string | |
| `logoUrl` / `coverUrl` | string | |
| `description` | string | |
| `category` | string | industry |
| `products` | array<map> | `{ name, price, currency, imageUrl }` (small lists; large catalogs → subcollection) |
| `services` | array<string> | |
| `contact` | map | `{ phone, email, whatsapp, address, geohash }` |
| `links` | map | website + socials |
| `verified` 🔒 | bool | verified business account |
| `ratingAvg` ⚡ / `ratingCount` ⚡ | number/int | from reviews |
| `followerCount` ⚡ | int | |
| `createdAt` | timestamp | |

Reviews live in `businesses/{id}/reviews/{uid}` (one per user; edge-style),
with a Function maintaining `ratingAvg`/`ratingCount`.

---

## `posts/{postId}`

The feed unit. Author data is **denormalized** so rendering is join-free.

| Field | Type | Notes |
|-------|------|-------|
| `authorId` | string | |
| `author` ↗ | map | `{ handle, displayName, photoUrl, verified }` snapshot |
| `type` | enum | `text` \| `image` \| `video` \| `article` \| `poll` \| `business_update` |
| `text` | string | body/caption |
| `media` | array<map> | `{ url, type, width, height, thumbUrl, muxPlaybackId? }` |
| `article` | map? | `{ title, coverUrl, bodyHtml, readingMins }` for long-form |
| `poll` | map? | `{ question, options:[{id,text,voteCount⚡}], endsAt }` |
| `hashtags` | array<string> | parsed; drives `hashtags/{tag}` |
| `mentions` | array<string> | uids |
| `visibility` | enum | `public` \| `followers` \| `private` |
| `likeCount` ⚡ / `commentCount` ⚡ / `shareCount` ⚡ / `saveCount` ⚡ | int | |
| `viewCount` ⚡ | int | sampled/batched to limit writes |
| `score` 🔒⚡ | number | FYP ranking score (recomputed by ranking function) |
| `isSponsored` | bool | set when boosted/an ad creative |
| `createdAt` | timestamp | |
| `editedAt` | timestamp? | |
| `removed` 🔒 | bool | soft-delete by moderation |

- **`posts/{postId}/comments/{commentId}`** — `{ authorId, author↗, text, likeCount⚡, parentId?, createdAt }` (supports one-level threads via `parentId`).
- **`posts/{postId}/likes/{uid}`** — existence = liked; `{ createdAt }`. A Function batches these into `likeCount`. Cheap "did I like this?" check by doc-get.
- **Saves** live in `users/{uid}/saved/{postId}` (private to the user).

---

## `founderJourneys/{journeyId}` ⭐

The platform's flagship object — structured so it can be prompted, discovered,
and templated (not just free text). A journey can be authored incrementally.

| Field | Type | Notes |
|-------|------|-------|
| `authorId` / `author` ↗ | string / map | |
| `businessId` | string? | linked business |
| `title` | string | e.g. "From $200 to 50 employees" |
| `industry` | string | |
| `startupCapital` | map | `{ amount, currency, disclosed: bool }` |
| `timeline` | array<map> | `{ date, milestone, detail, mediaUrl? }` ordered |
| `challenges` | array<string> | |
| `mistakes` | array<string> | |
| `lessons` | array<string> | |
| `currentStage` | enum | `idea` \| `mvp` \| `revenue` \| `growth` \| `scaled` |
| `metrics` | map? | optional `{ revenueBand, teamSize, fundingRaised }` |
| `likeCount` ⚡ / `saveCount` ⚡ / `viewCount` ⚡ | int | |
| `featured` 🔒 | bool | editorial/admin highlight |
| `createdAt` / `updatedAt` | timestamp | |

This powers a dedicated **"Journeys"** discovery tab, inspiration prompts, and
the AI assistant's "help me write my founder story" flow.

---

## `stories/{storyId}` (24h ephemeral)

| Field | Type | Notes |
|-------|------|-------|
| `authorId` / `author` ↗ | string / map | |
| `type` | enum | `image` \| `video` \| `text` \| `business_announcement` \| `promo` |
| `media` | map | `{ url, thumbUrl, durationMs }` |
| `text` / `bgColor` | string | for text stories |
| `cta` | map? | `{ label, url }` for promos |
| `viewCount` ⚡ | int | |
| `createdAt` | timestamp | |
| `expiresAt` | timestamp | **Firestore TTL policy** auto-deletes 24h docs |

Views recorded in `stories/{id}/views/{uid}`. Configure a **TTL policy on
`expiresAt`** so Google reaps expired stories (no manual sweeper needed; a
scheduled function is a backstop).

---

## `follows/{followerUid_followingUid}`

Edge doc; id is the composite so the "do I follow X?" check is a single get.

| Field | Type |
|-------|------|
| `followerId` | string |
| `followingId` | string |
| `createdAt` | timestamp |

A Function maintains `followerCount`/`followingCount` and (optionally) fans new
posts into `users/{follower}/home`. For very large accounts, prefer
**fan-out-on-read** (query author set) over fanning to millions of inboxes.

---

## `conversations/{conversationId}` + messages

| Field (conversation) | Type | Notes |
|----------------------|------|-------|
| `memberIds` | array<string> | used by rules: `request.auth.uid in memberIds` |
| `members` ↗ | map | `{ uid: {handle, displayName, photoUrl} }` snapshots |
| `type` | enum | `direct` \| `group` |
| `title` / `photoUrl` | string | for groups |
| `lastMessage` ↗ | map | `{ text, senderId, type, createdAt }` for list previews |
| `unread` ⚡ | map | `{ uid: count }` per-member unread |
| `createdAt` / `updatedAt` | timestamp | |

| Field (message) | Type | Notes |
|-----------------|------|-------|
| `senderId` | string | |
| `type` | enum | `text` \| `image` \| `video` \| `file` |
| `text` | string | |
| `media` | map? | `{ url, type, name, size, thumbUrl }` |
| `readBy` | array<string> | |
| `createdAt` | timestamp | |

Realtime via listeners. `onCreate(messages)` Function updates `lastMessage`,
increments `unread` for other members, and sends push.

---

## Monetization collections (🔒 server-owned)

### `verificationRequests/{requestId}`
State machine for the paid verification flow.

| Field | Type | Notes |
|-------|------|-------|
| `userId` | string | |
| `status` 🔒 | enum | `pending_payment` → `paid` → `in_review` → `approved` \| `rejected` |
| `subjectType` | enum | `user` \| `business`; `subjectId` | string |
| `documents` | array<map> | `{ storagePath, kind }` uploaded to a locked Storage path |
| `paymentId` 🔒 | string | links to `payments/{id}` |
| `amount` / `currency` | number / string | |
| `reviewerId` 🔒 / `reviewNote` 🔒 | string | admin audit |
| `createdAt` / `updatedAt` | timestamp | |

Client may **create** a request (status forced to `pending_payment` by rules) and
read its own; only Functions advance status.

### `payments/{paymentId}` 🔒 (immutable ledger)
Written **only** by webhook Functions. Never client-writable, never updated.

| Field | Type | Notes |
|-------|------|-------|
| `userId` | string | |
| `provider` | enum | `stripe` \| `flutterwave` \| `paystack` \| `revenuecat` \| `play` \| `appstore` |
| `providerRef` | string | charge/order/transaction id (idempotency key) |
| `purpose` | enum | `verification` \| `premium` \| `ad_spend` \| `boost` |
| `amount` / `currency` | number / string | |
| `status` | enum | `succeeded` \| `refunded` \| `failed` |
| `metadata` | map | relatedId (requestId/campaignId), raw provider event id |
| `createdAt` | timestamp | |

### `subscriptions/{uid}` 🔒 (premium entitlement)
Source of truth for premium; mirrored to `users/{uid}.premium` + custom claim.

| Field | Type | Notes |
|-------|------|-------|
| `plan` | enum | `free` \| `pro` \| `business` |
| `status` | enum | `active` \| `grace` \| `canceled` \| `expired` |
| `provider` | enum | `revenuecat` \| `stripe` | `entitlements` | array<string> |
| `renewsAt` / `startedAt` | timestamp | |

---

## Advertising

### `adCampaigns/{campaignId}`
| Field | Type | Notes |
|-------|------|-------|
| `advertiserId` | string | |
| `objective` | enum | `awareness` \| `traffic` \| `engagement` \| `leads` |
| `status` 🔒 | enum | `draft` → `pending_review` → `active` → `paused`/`completed`/`rejected` |
| `budget` | map | `{ total, daily, currency, spent⚡ }` |
| `schedule` | map | `{ startAt, endAt }` |
| `targeting` | map | `{ industries[], locations[], accountTypes[], interests[] }` |
| `paymentId` 🔒 | string | funding |
| `metrics` ⚡ | map | `{ impressions, clicks, ctr }` |

### `adCampaigns/{campaignId}/ads/{adId}`
Creatives: `{ placement: feed|story|video|listing, postId?, media, cta, status }`.
Approved ads are eligible for insertion into feeds/stories by the ranking layer.

---

## `liveStreams/{streamId}`
| Field | Type | Notes |
|-------|------|-------|
| `hostId` / `host` ↗ | string / map | |
| `title` / `category` | string | |
| `status` 🔒 | enum | `scheduled` \| `live` \| `ended` |
| `agoraChannel` 🔒 | string | token issuance handled by Function |
| `viewerCount` ⚡ / `peakViewers` ⚡ | int | |
| `startedAt` / `endedAt` | timestamp | |
| `vodPlaybackId` | string? | optional recorded VOD (Mux) |

Live chat/reactions: `liveStreams/{id}/chat/{msgId}` or Agora RTM for scale.

---

## Supporting collections

| Collection | Purpose / key fields |
|------------|----------------------|
| `users/{uid}/notifications/{id}` | `{ type, actor↗, targetId, read, createdAt }` — likes, comments, follows, mentions, system, verification, ad, live |
| `reports/{reportId}` | `{ reporterId, targetType, targetId, reason, status, createdAt }` — create-only by users; resolved by moderators |
| `hashtags/{tag}` | `{ tag, postCount⚡, score⚡, updatedAt }` — trending |
| `referrals/{code}` | `{ ownerUid, uses⚡, signups⚡, createdAt }` — referral tracking (Branch attribution writes here) |
| `adminAudit/{id}` 🔒 | `{ adminId, action, targetType, targetId, before, after, at }` — every privileged action |
| `handles/{handle}` | `{ uid }` — uniqueness reservation for `@handles` |
| `counters/{doc}` | optional sharded counters for ultra-hot aggregates |

---

## Indexing & query notes

Composite indexes (see [`firestore.indexes.json`](../firestore.indexes.json)) are
required for, e.g.:

- Profile feed: `posts` where `authorId == X` order by `createdAt desc`.
- FYP candidate pull: `posts` where `visibility == public` order by `score desc, createdAt desc`.
- Category discovery: `posts` where `hashtags array-contains <tag>` order by `createdAt desc`.
- New users: `users` where `isNewUser == true` order by `createdAt desc`.
- Conversations list: `conversations` where `memberIds array-contains uid` order by `updatedAt desc`.
- Notifications: `users/{uid}/notifications` where `read == false` order by `createdAt desc`.
- Ads serving: `adCampaigns/.../ads` where `status == active` (+ targeting filters).

**Anti-patterns to avoid:** counting documents on read; unbounded `array-contains-any`;
fanning posts to millions of inboxes; storing video bytes only in Storage with no
CDN/HLS; using Firestore for free-text search (use Algolia).
