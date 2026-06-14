# MySpot — Local Setup (Phase P0)

Concrete steps to run the scaffold. Prereqs: **Flutter (stable)**, **Node 20**,
**Java 17** (for the Firestore emulator), the **Firebase CLI**, and the
**FlutterFire CLI**.

```bash
npm i -g firebase-tools
dart pub global activate flutterfire_cli
```

## 1. Create Firebase projects

Create three projects in the Firebase console (or `firebase projects:create`):
`myspot-dev`, `myspot-staging`, `myspot-prod`. Update [`.firebaserc`](.firebaserc)
if you use different IDs. Then:

```bash
firebase use dev
```

Enable in each project: **Authentication** (Email/Password, Phone, Google, Apple),
**Firestore**, **Storage**, **Functions** (Blaze plan required), **App Check**,
**Cloud Messaging**, **Remote Config**.

## 2. Wire the Flutter app to Firebase

```bash
cd app
flutter pub get
flutterfire configure --project=myspot-dev   # generates lib/firebase_options.dart (gitignored)
```

Then switch `app/lib/main.dart` to pass the generated options:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Add the platform config files the CLI references (`google-services.json`,
`GoogleService-Info.plist`) — both are gitignored.

## 3. Deploy rules & indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage --project myspot-dev
```

Configure the **TTL policy** on `stories.expiresAt` (console → Firestore → TTL,
or `gcloud firestore fields ttls update`).

## 4. Functions

```bash
cd functions
npm install
npm run build

# Secrets (never commit these):
firebase functions:secrets:set OPENAI_API_KEY
# Non-secret model IDs: copy functions/.env.example -> functions/.env and fill in.

firebase deploy --only functions --project myspot-dev
```

## 5. App Check (debug)

In debug builds the app uses App Check **debug providers**. Register the debug
token printed at first launch in the Firebase console (App Check → apps → manage
debug tokens) so callables (`claimHandle`, `aiAssist`) accept the client.

## 5b. Live streaming (Agora)

Create an Agora project (console.agora.io) and set:

```bash
# functions/.env  (app id is public)
AGORA_APP_ID=<your-agora-app-id>
# secret (token signing)
firebase functions:secrets:set AGORA_APP_CERTIFICATE
```

The app id is also needed client-side: the `createLiveStream`/`joinLiveStream`
callables return it with the token, so no client config is required. On **web**
live video shows a placeholder (Agora video renders on mobile via the conditional
import in `features/live/live_stage.dart`). iOS camera/mic prompts use the
Info.plist strings already added; if you gate on `permission_handler` results on
iOS, add its camera/microphone macros to the generated `ios/Podfile` post-install.

## 5c. In-app purchases (RevenueCat) — mobile premium

App-store policy requires native billing for in-app digital goods, so on mobile
premium is bought via RevenueCat (web uses Paystack hosted checkout).

1. In RevenueCat: create the app, add Play/StoreKit subscription products, an
   **entitlement** named `premium`, and an Offering with `pro`/`business` packages.
2. Put the public SDK keys in `app/lib/core/config/app_config.dart`
   (`revenueCatIosKey` / `revenueCatAndroidKey`).
3. Set the webhook: RevenueCat → Integrations → Webhooks → URL =
   `https://<region>-<project>.cloudfunctions.net/revenueCatWebhook`, with an
   `Authorization: Bearer <token>` header; then
   `firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH` to that token.

The client triggers the purchase; the webhook is the source of truth that grants
`premium` (mirrored to `subscriptions/{uid}` + custom claim). On web the keys stay
`REPLACE_*` and IAP is simply disabled.

## 5d. Observability (Analytics, Crashlytics, Performance)

`core/observability` wires Firebase Analytics (screen tracking via a go_router
observer), Crashlytics (uncaught Flutter + async errors), and Performance
Monitoring. Crashlytics and Performance are **mobile-only** — on web they're a
no-op (guarded by `kIsWeb`), and Analytics works on all platforms.

Native build config is required for the **Android** Crashlytics Gradle plugin
(iOS works via the pod that FlutterFire adds). With the Flutter Gradle plugin
DSL, add to `android/settings.gradle`:

```groovy
plugins {
  // ...existing google-services line from flutterfire configure...
  id "com.google.firebase.crashlytics" version "3.0.2" apply false
}
```

and to `android/app/build.gradle`:

```groovy
plugins {
  // ...
  id "com.google.gms.google-services"
  id "com.google.firebase.crashlytics"
}
```

Collection is disabled in debug builds; verify a forced test crash reaches the
Crashlytics dashboard before release. Analytics events and crashes need no
client keys beyond the standard `firebase_options.dart`.

## 6. Run

```bash
# Emulators (auth, firestore, functions, storage):
firebase emulators:start

# App against a device/emulator:
cd app && flutter run
```

The router flow: **/sign-in → /onboarding (first run) → tab shell**. On sign-up,
the `onUserCreate` Function provisions the user doc, claims, and a default handle.

## 7. Tests

```bash
# Flutter
cd app && flutter analyze && flutter test

# Firestore rules (needs Java 17)
firebase emulators:exec --only firestore --project demo-myspot "npm --prefix test test"

# Functions typecheck
cd functions && npm run build
```

CI runs all three on every push/PR — see `.github/workflows/ci.yml`.

## What P0 delivers

Auth (email, Google, Apple, and phone/OTP), first-run onboarding (handle claim +
profile), the 5-tab shell, and a profile screen reading the live `users/{uid}`
doc — on a secured backend (rules deployed, App Check, server-provisioned
identity). Subsequent phases (feed, journeys, messaging, live, monetization, AI,
admin) build on this per [docs/08-roadmap.md](docs/08-roadmap.md).

**Apple & phone providers:** both use Firebase Auth's built-in flows (no extra
package). For Apple, enable the provider in the Firebase console and configure
the Apple Service ID / Sign in with Apple capability (iOS) per the console
wizard. For phone, enable Phone auth, add your SHA-256 + APNs key (Android/iOS),
and register App Check / reCAPTCHA for web. Test numbers can be added in the
console while developing.
