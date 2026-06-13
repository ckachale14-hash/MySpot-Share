# 13 · Live Streaming Architecture

Goal: low-latency, scalable live video for **business discussions, product
launches, Q&A, and entrepreneurship lessons** — with live chat, reactions,
recording, and replay. Built on a managed RTC vendor (**Agora**; 100ms/LiveKit
are alternatives) because running media servers yourself doesn't pay off pre-scale.

## 1. Why a managed vendor

Live video at scale needs SFU/relay infrastructure, adaptive bitrate, global
edge, and mobile SDKs. Agora's **interactive live streaming** mode distinguishes
**hosts** (publish) from **audience** (subscribe), scaling to large viewer counts
cheaply — exactly our shape (few hosts, many viewers).

## 2. Components & roles

| Role | Capability |
|------|-----------|
| **Host** | publishes audio/video; controls stream; moderates chat; may invite co-hosts |
| **Co-host (guest)** | promoted viewer who can publish (panel/interview) |
| **Viewer** | subscribes to host video; sends chat & reactions; can request to join |

## 3. Token security (server-authoritative)

```
Host taps "Go Live"
  → callable createLiveStream() ★
       • create liveStreams/{id} = { status:'live', hostId, agoraChannel, ... }
       • mint host RTC token (publisher) using Agora app certificate (Secret Manager)
       • return channel + token
Viewer opens stream
  → callable joinLiveStream(streamId) ★
       • verify stream is live; mint viewer RTC token (subscriber)
       • increment viewerCount; return token
```
The Agora **app certificate never ships in the client**; tokens are short-lived,
role-scoped, and per-channel. See [10 §Live](10-cloud-functions.md).

## 4. Live chat & reactions

- **MVP:** `liveStreams/{id}/chat/{msgId}` Firestore subcollection — realtime
  listeners deliver messages; reactions as lightweight docs or aggregated counts.
- **At scale:** move chat to **Agora RTM** (or a pub/sub channel) to avoid
  Firestore write hotspots on viral streams; persist only a sample/highlights.
- Reactions (❤️🔥👏) are high-frequency → **aggregate client-side and batch**
  (e.g., counts per second) rather than one doc per tap.
- **Moderation:** host/moderators can delete messages, mute, or ban viewers
  (rules allow moderator writes; host actions via callable).

## 5. Recording & replay (VOD)

```
Host ends → callable endLiveStream() ★
  • status = 'ended', set endedAt, peakViewers
  • (optional) Agora Cloud Recording → storage → transcode to HLS via Mux
  • write vodPlaybackId on liveStreams/{id}
Replay → viewers stream the Mux HLS VOD (adaptive bitrate, CDN)
```
Recording is opt-in per stream. VOD playback uses **Mux/Cloudflare Stream HLS +
CDN**, never raw Storage egress.

## 6. Scale & resilience

| Concern | Approach |
|---------|----------|
| Many viewers, few hosts | Agora live-broadcast mode (audience subscribe-only) |
| Chat hotspots on viral streams | RTM / pub-sub for chat; Firestore for metadata only |
| Reaction floods | client-side aggregation + batched counts |
| Viewer count accuracy | join/leave callables + presence; periodic reconcile |
| Africa bandwidth | low-bitrate/adaptive profiles; audio-only fallback; "data saver" |
| Abuse | App Check on join/create; rate-limit chat; ban/mute tools |
| Cost | per-minute RTC + recording + VOD egress — cap concurrent minutes per plan; premium-gate long streams |

## 7. Data model touchpoints

`liveStreams/{id}` (status, host snapshot, `agoraChannel` 🔒, viewerCount⚡,
peakViewers⚡, vodPlaybackId) and `liveStreams/{id}/chat/{msgId}` — see
[02 §liveStreams](02-firestore-data-model.md#livestreamsstreamid).

## 8. UX surfaces

Go-Live composer (title, category, audio/video toggle), live host console
(viewers, chat moderation, invite co-host, end), live viewer (video, chat,
reactions, follow host, share), and live discovery (currently live by viewers).
See [05 §Live](05-screens-and-navigation.md).

## 9. Notifications

On go-live, notify followers (FCM, throttled) and surface in live discovery —
a key driver of concurrent viewership.
