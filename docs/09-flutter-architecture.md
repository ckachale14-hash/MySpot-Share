# 09 · Flutter App Architecture

## 1. Principles

- **Feature-first, layered.** Each feature owns its UI, controllers, and data
  access; shared concerns live in `core/`.
- **Unidirectional data flow.** UI watches state → controllers call repositories
  → repositories talk to Firebase/Functions → streams push updates back.
- **Thin client.** No money/identity/ranking logic on the device.
- **Testable.** Repositories are interfaces; controllers are pure-ish and unit
  tested; rules tested against the emulator.

```
Presentation (Screens/Widgets)
      │ watch (Riverpod)
Application (Controllers: AsyncNotifier / Notifier, AsyncValue<T>)
      │ call
Domain (Entities, repository interfaces, small use-cases)
      │ implemented by
Data (Repository impls → Firestore/Storage/Functions datasources, DTO↔entity)
```

## 2. State management & routing

- **Riverpod** (`flutter_riverpod` + `riverpod_annotation`/`riverpod_generator`)
  — compile-safe providers, easy testing/overrides, `AsyncValue` for
  loading/error/data.
- **go_router** — declarative, deep-link-first (see route table in
  [05](05-screens-and-navigation.md)); `StatefulShellRoute` for the 5-tab shell
  with preserved state; redirects gate auth/verification/premium.

> **Bloc alternative:** if the team prefers Bloc/Cubit, the layering is identical
> — swap the Application layer. Decide once, keep it consistent.

## 3. Target folder structure

```
app/lib/
├── main.dart                       # bootstrap: Firebase, App Check, ProviderScope
├── firebase_options.dart           # generated (gitignored)
├── core/
│   ├── config/                     # env/flavors, Remote Config keys, constants
│   ├── theme/                      # Material 3 theme, colors, typography, spacing
│   ├── router/                     # go_router config, routes, guards
│   ├── di/                         # provider wiring (firebase, repos)
│   ├── widgets/                    # shared catalog: PostCard, StoryRing,
│   │                               #   VerifiedBadge, UserTile, BusinessCard,
│   │                               #   JourneyTimeline, EngagementBar, AdCard
│   ├── services/                   # AppCheck, analytics, messaging, deeplinks
│   └── utils/                      # formatters, validators, result types
├── domain/
│   ├── entities/                   # User, Post, Story, Business, Journey,
│   │                               #   Conversation, Message, AdCampaign...
│   └── repositories/               # abstract interfaces
├── data/
│   ├── dtos/                       # Firestore <-> entity mapping (json/codegen)
│   ├── datasources/                # FirestoreX, StorageX, FunctionsX wrappers
│   └── repositories/               # concrete repo impls
└── features/
    ├── auth/                       # screens + controllers + providers
    ├── onboarding/
    ├── feed/                       # home/FYP, post detail, composer
    ├── stories/
    ├── journeys/                   # founder journeys ⭐
    ├── profile/
    ├── business/
    ├── discover/                   # search, people, trending, directory
    ├── messaging/
    ├── live/
    ├── notifications/
    ├── monetization/               # verification, premium paywall, ads manager
    └── settings/
```

The **admin panel** can be a separate `admin/` Flutter Web target that reuses
`domain/` + `data/` (shared package) or a top-level flavor of the same app gated
by the `admin` claim.

## 4. Recommended packages

| Concern | Packages |
|---------|----------|
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cloud_functions`, `firebase_messaging`, `firebase_app_check`, `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`, `firebase_remote_config` |
| State/routing | `flutter_riverpod`, `riverpod_annotation`, `go_router` |
| Auth providers | `google_sign_in`, `sign_in_with_apple` |
| Media | `image_picker`, `cached_network_image`, `video_player`, `chewie`, image compression |
| Payments | `purchases_flutter` (RevenueCat), `flutter_stripe` |
| Live | `agora_rtc_engine` |
| Search | `algolia` client (search-only key) |
| Deep links | Branch SDK (`flutter_branch_sdk`), `app_links` |
| Misc | `share_plus`, `freezed`/`json_serializable`, `intl`, `flutter_hooks` (optional) |

## 5. Representative code (contracts, not full impls)

### 5.1 Entity (immutable, `freezed`)
```dart
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String authorId,
    required AuthorRef author,      // denormalized snapshot
    required PostType type,
    @Default('') String text,
    @Default([]) List<MediaItem> media,
    @Default([]) List<String> hashtags,
    @Default(PostVisibility.public) PostVisibility visibility,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int shareCount,
    @Default(false) bool isSponsored,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

### 5.2 Repository interface (domain) + Firestore impl (data)
```dart
// domain/repositories/feed_repository.dart
abstract interface class FeedRepository {
  Stream<List<Post>> watchHomeFeed({int limit = 20});
  Future<void> createPost(NewPost draft);
  Future<void> like(String postId);     // writes posts/{id}/likes/{uid}
  Future<void> unlike(String postId);
}

// data/repositories/firestore_feed_repository.dart
class FirestoreFeedRepository implements FeedRepository {
  FirestoreFeedRepository(this._db, this._auth, this._functions);
  // ...
  @override
  Future<void> like(String postId) async {
    final uid = _auth.currentUser!.uid;
    await _db.doc('posts/$postId/likes/$uid').set({'createdAt': now()});
    // likeCount is incremented by a Cloud Function — never client-side.
  }
}
```

### 5.3 Controller (application) with Riverpod
```dart
@riverpod
class HomeFeedController extends _$HomeFeedController {
  @override
  Stream<List<Post>> build() =>
      ref.watch(feedRepositoryProvider).watchHomeFeed();

  Future<void> like(String postId) =>
      ref.read(feedRepositoryProvider).like(postId); // optimistic UI in widget
}
```

### 5.4 Calling the AI assistant (callable Function)
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('aiAssist')
    .call({'task': 'rewrite', 'text': draft, 'tone': 'professional'});
final improved = result.data['text'] as String;
// API keys & model selection are entirely server-side (see docs/10).
```

## 6. Conventions

- **Naming:** features `snake_case` folders; classes `PascalCase`; providers
  end in `Provider`/`Controller`.
- **No raw Firestore in widgets** — always via a repository.
- **`AsyncValue` everywhere** for async UI (loading/error/data + skeletons).
- **Errors:** typed failures from repos; user-friendly messages in UI;
  Crashlytics for the rest.
- **Codegen:** `freezed` + `json_serializable` for entities/DTOs; `riverpod_generator`
  for providers (`dart run build_runner`).
- **Testing:** unit (controllers/repos with fakes), widget (key screens),
  integration (golden flows on emulator), rules tests in CI.
- **Performance:** `const` widgets, list virtualization, cached images, paginated
  queries, image compression before upload.

## 7. App bootstrap (main.dart sketch)
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(/* Play Integrity / DeviceCheck */);
  await FirebaseFirestore.instance
      .setPersistenceEnabled(true); // offline-first
  runApp(const ProviderScope(child: MySpotApp()));
}
```
