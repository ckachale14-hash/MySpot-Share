// GENERATED-STYLE PLACEHOLDER — replace by running `flutterfire configure`,
// or supply values at build time via --dart-define (see the `web` block below).
//
// This file mirrors the shape FlutterFire generates so `main.dart` compiles
// today. Running `flutterfire configure --project=<your-project>` overwrites it
// with your real values (Firebase web API keys are public-by-design and safe to
// commit).
//
// For the web/Vercel build we keep this file placeholder-clean and read the web
// config from compile-time environment values (`--dart-define=...`). The Vercel
// build script (`scripts/vercel-build.sh`) forwards the matching env vars, so
// the real config lives in the Vercel project settings, not in git. If a value
// is not supplied at build time it falls back to the REPLACE_* placeholder, and
// Firebase calls will fail at runtime with an invalid key.
//
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform — '
          'run `flutterfire configure` to regenerate firebase_options.dart.',
        );
    }
  }

  // Web config is supplied at build time via --dart-define (forwarded by
  // scripts/vercel-build.sh from the Vercel environment variables). Values fall
  // back to REPLACE_* placeholders when not provided.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'REPLACE_WITH_WEB_API_KEY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_WEB_APP_ID',
      defaultValue: 'REPLACE_WITH_WEB_APP_ID',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: 'REPLACE_WITH_SENDER_ID',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'REPLACE_WITH_PROJECT_ID',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'REPLACE_WITH_PROJECT_ID.appspot.com',
    ),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.appspot.com',
    iosBundleId: 'com.myspotshare.app',
  );
}
