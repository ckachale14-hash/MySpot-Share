# 03 · Security Rules & Trust Model

The concrete rules live in [`firestore.rules`](../firestore.rules) and
[`storage.rules`](../storage.rules). This document explains **why** they're shaped
that way so reviewers and future contributors don't accidentally open holes.

## 1. The one rule that governs all rules

> **Anything that affects money, identity, privilege, or ranking is decided by
> Cloud Functions (Admin SDK), never by the client.**

Cloud Functions use the Admin SDK, which **bypasses** security rules. So the
rules' job is to:
1. Let users manage **their own public content** within tight field constraints.
2. Make **privilege/money/ranking fields unwritable** from any client.
3. Enforce **ownership and membership** on edges (likes, follows, messages).

## 2. Identity & roles

- **Authentication:** Firebase Auth (email, phone, Google, Apple). Every rule
  starts from `request.auth`.
- **Roles via custom claims:** `role ∈ {user, moderator, admin}` is set on the
  Auth token by a Function and read in rules as `request.auth.token.role`.
  `users/{uid}.role` is a **mirror** for display/queries; the claim is the
  authority. Changing a role requires a Function (which updates both the claim
  and the mirror and writes `adminAudit`).
- **`verified` and `premium`** are likewise mirrored to claims so the client can
  *render* state instantly, but only Functions can *change* them.

## 3. Server-only fields pattern

Rules cannot "trust" a field the client sends. Two enforcement techniques are
used throughout:

- **On create:** assert privileged/counter fields equal their safe defaults
  (`verified == false`, `*Count == 0`, `status == 'pending_payment'`, etc.).
- **On update:** assert the update doesn't touch them, via
  `untouched([...])` → `!affectedKeys().hasAny([...])`. The owner can edit body
  fields freely, but a write that changes `likeCount` or `verified` is rejected.

`onlyKeys([...])` is the inverse — used where the client may change *exactly*
one thing (e.g. flip `read` on a notification, or `readBy` on a message).

## 4. Trust boundaries per domain

| Domain | Client may… | Only Functions may… |
|--------|-------------|---------------------|
| Profile | edit name/bio/photo/links | set `verified`, `premium`, `role`, counters |
| Posts | create/edit/delete own body | set `likeCount`, `score`, `isSponsored`, `removed` |
| Likes/Follows | add/remove own edge | recompute counts |
| Comments | create/edit/delete own | counts; delete-by-post-author allowed in rules |
| Messages | send in conversations they're a member of; mark read | bump `lastMessage`, `unread`, push |
| Verification | open a `pending_payment` request, read own | advance status, attach `paymentId`, approve |
| Payments | read own | **all writes** (webhook-verified) |
| Subscriptions | read own | **all writes** (RevenueCat/Stripe webhooks) |
| Ads | edit own draft, submit for review | approve, set `spent`/`metrics`, charge |
| Live | create own stream doc, send chat | issue Agora tokens, set `agoraChannel`, viewer counts |
| Reports | create | read/resolve (moderators) |
| Trending/Audit | read (audit: admin) | **all writes** |

## 5. Membership & ownership checks

- **Conversations** gate on `request.auth.uid in resource.data.memberIds`.
  Messages re-check membership via `get()` on the parent conversation.
- **Follows** use a composite doc id `"<follower>_<following>"` and assert the
  id matches the claimed `followerId == auth.uid` — preventing a user from
  forging someone else's follow.
- **Likes/views** are stored at `/likes/{uid}` and `/views/{uid}`, so the rule
  is simply `isUser(uid)` and a user can't like "as" someone else.

> **`get()` cost note:** cross-document `get()` in rules counts as a read and adds
> latency. It's used sparingly (messages → conversation membership; comment
> deletion → post author). Hot paths avoid it by encoding identity into the doc id.

## 6. Storage rules highlights

- All UGC is namespaced under the **owner's uid**; only the owner writes there.
- **Size/content-type caps** (images ≤10 MB, video ≤200 MB, KYC docs ≤15 MB)
  blunt abuse and runaway egress.
- **Verification/KYC documents are private** (`read: if false`). Admins review
  them through **server-minted signed URLs**, never public read — critical for
  handling identity documents responsibly.
- Chat attachments are readable by signed-in users (URLs are unguessable);
  for stricter privacy, switch to **short-lived signed URLs** issued by a Function.

## 7. App Check & abuse

- **App Check** (Play Integrity / DeviceCheck / reCAPTCHA) is enforced on
  Callable Functions and, where available, on Firestore/Storage — so only
  genuine app builds reach the backend.
- **Rate limiting & quotas** for AI, messaging, and posting are enforced in
  Functions (rules can't rate-limit).
- **reCAPTCHA** on auth flows; report→moderation loop for content.

## 8. What rules deliberately do *not* do

Rules are a backstop, not the whole security story. These are enforced elsewhere:
- **Content moderation** (text/image safety) → Functions + Vertex/Perspective.
- **Payment correctness** → webhook signature verification in Functions.
- **Ranking/visibility business logic** → ranking Functions.
- **Complex cross-entity invariants** → Functions + transactions.

## 9. Testing the rules (required)

Add **`@firebase/rules-unit-testing`** tests to CI covering at minimum:
- a user cannot set their own `verified`/`premium`/`role`;
- a user cannot write another user's post, like, or message;
- a non-member cannot read a conversation or its messages;
- `payments`/`subscriptions` reject all client writes;
- a verification request can only be created as `pending_payment`;
- KYC documents are not publicly readable.

Run them against the **Firestore emulator** on every PR before deploying rules.
