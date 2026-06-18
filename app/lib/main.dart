import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/observability/observability.dart';
import 'features/monetization/purchases_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uses committed placeholder options until you run `flutterfire configure`,
  // which regenerates firebase_options.dart with your real project config.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // App Check gates the backend (callables enforce it). Debug providers are used
  // in debug builds; switch to Play Integrity / DeviceCheck for release.
  //
  // Web needs an explicit reCAPTCHA provider — calling activate() without one on
  // web throws at startup. We only activate on web when a site key is supplied
  // (RECAPTCHA_V3_SITE_KEY via --dart-define / Vercel env); otherwise we skip it
  // so the app still boots. Register the key in Firebase Console → App Check.
  const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_V3_SITE_KEY');
  if (kIsWeb) {
    if (recaptchaSiteKey.isNotEmpty) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(recaptchaSiteKey),
      );
    }
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  }

  // Crash reporting, performance, and analytics (Crashlytics/Perf are
  // mobile-only and no-op on web).
  await initObservability();

  // Configure in-app purchases (no-op on web / until RevenueCat keys are set).
  try {
    await PurchasesService().configure();
  } catch (_) {}

  runApp(const ProviderScope(child: MySpotApp()));
}
