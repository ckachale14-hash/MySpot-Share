# 14 · Messaging Architecture (WhatsApp-like)

Realtime direct & group messaging with media, read receipts, online status, and
typing indicators. Built **realtime-first on Firestore** (fast to ship, scales
well for chat-sized writes) with **Realtime Database** for presence.

## 1. Why this split

| Need | Service | Why |
|------|---------|-----|
| Messages, conversations, history | **Cloud Firestore** | realtime listeners, offline cache, security rules, pagination |
| **Online status / presence** | **Realtime Database** | native `onDisconnect()` — the right tool for "last seen / online" |
| Media attachments | **Cloud Storage** | size-capped, owner-scoped |
| Delivery + unread + push | **Cloud Functions + FCM** | trusted fan-out |

Firestore alone can't reliably detect disconnects; RTDB presence is the standard
pattern. Everything else lives in Firestore.

## 2. Data model (recap)

`conversations/{cid}` — `memberIds[]`, denormalized `members` snapshots,
`lastMessage`, per-member `unread` map, `type` (direct|group), `updatedAt`.
`conversations/{cid}/messages/{mid}` — `senderId`, `type`, `text`, `media`,
`readBy[]`, `createdAt`. Full schema in
[02 §conversations](02-firestore-data-model.md#conversationsconversationid--messages).

Security: only `memberIds` can read; only a member can send (`senderId == uid`);
messages updatable only to mark `readBy` — see [`firestore.rules`](../firestore.rules).

## 3. Core flows

```
Open chat
  → find-or-create conversations/{cid} (deterministic id for DMs: sorted uids)
  → listen messages (orderBy createdAt desc, paginated)

Send message (optimistic)
  → write message (rules verify membership)
  → onCreate(messages) Function ★:
       • update conversation.lastMessage + updatedAt
       • increment unread for OTHER members
       • send FCM push to recipients (respect mute/prefs)

Read
  → mark messages readBy += uid; reset my unread counter
  → sender sees read receipts via readBy

Media
  → upload to users/{uid}/chat/{cid}/... (capped) → send message with media ref
```

## 4. Online status, typing, receipts

- **Presence (RTDB):** on connect, write `/status/{uid} = online` with
  `onDisconnect()` set to `{ offline, lastSeen: ts }`. A Function can mirror a
  coarse `lastActiveAt` to Firestore for queries. Respect a privacy setting to
  hide "last seen".
- **Typing indicators:** ephemeral RTDB flag under the conversation (auto-expire),
  not Firestore writes (avoids history churn).
- **Receipts:** `sent` (write ok) → `delivered` (recipient device ack/FCM) →
  `read` (`readBy` contains uid). Group reads show per-member.

## 5. Group chats

Same model with `type=group`, `title`, `photoUrl`, and a larger `memberIds`.
Admin actions (add/remove member, rename) go through a callable so membership
changes are validated and audited; large groups cap membership and may move
fan-out push to batched sends.

## 6. Scale considerations

| Pressure | Strategy |
|----------|----------|
| Hot conversations | subcollection per conversation isolates writes; paginate history |
| Unread counters | per-member map updated in the onCreate Function (atomic) |
| Large groups | cap size; batch push; consider read-fan-out limits |
| Search in chat | client-side over loaded window; server index only if needed |
| Storage growth | lifecycle policies on old media; thumbnails for previews |
| Abuse/spam | App Check, rate limits, block list, report → moderation |

## 7. Privacy & security

- Transport is encrypted (TLS) and access is rules-gated to members.
- **True end-to-end encryption** (Signal-style) is **not** provided by the
  Firestore model — call this out honestly. If E2E becomes a requirement (e.g.
  sensitive deal rooms), it's a dedicated later workstream (client-side key
  management, encrypted payloads, separate from search/preview features).
- Block & report from any chat; blocked users can't initiate conversations.

## 8. Notifications

FCM push on new message (deep-links to the thread), muted per-conversation,
batched for groups, and suppressed when the recipient is actively viewing the
thread.

## 9. Flutter

`cloud_firestore` listeners for messages, `firebase_database` for presence/typing,
`firebase_storage` for media, `firebase_messaging` for push. Optimistic send with
local pending state reconciled by the listener.
