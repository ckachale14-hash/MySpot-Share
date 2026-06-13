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

Auth (email + Google; Apple/phone to wire), first-run onboarding (handle claim +
profile), the 5-tab shell, and a profile screen reading the live `users/{uid}`
doc — on a secured backend (rules deployed, App Check, server-provisioned
identity). Subsequent phases (feed, journeys, messaging, live, monetization, AI,
admin) build on this per [docs/08-roadmap.md](docs/08-roadmap.md).
