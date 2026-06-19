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

  // The web Firebase config is injected at build time via --dart-define
  // (forwarded by scripts/vercel-build.sh from the Vercel environment
  // variables). If those env vars aren't wired up, firebase_options.dart falls
  // back to its REPLACE_* placeholders and Firebase.initializeApp throws — which
  // on web leaves a blank, unresponsive page because the runApp() at the bottom
  // never runs. Detect that up front and render an actionable screen instead of
  // failing silently, so a misconfigured deploy is obvious rather than dead.
  final missingKeys = _missingFirebaseConfigKeys();
  if (missingKeys.isNotEmpty) {
    runApp(_StartupErrorApp(missingKeys: missingKeys));
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase.initializeApp failed: $e\n$stack');
    runApp(_StartupErrorApp(error: e.toString()));
    return;
  }

  // App Check gates the backend (callables enforce it). Debug providers are used
  // in debug builds; switch to Play Integrity / DeviceCheck for release.
  //
  // Web needs an explicit reCAPTCHA provider — calling activate() without one on
  // web throws at startup. We only activate on web when a site key is supplied
  // (RECAPTCHA_V3_SITE_KEY via --dart-define / Vercel env); otherwise we skip it
  // so the app still boots. Register the key in Firebase Console → App Check.
  //
  // Activation is best-effort: an unregistered domain or a wrong reCAPTCHA key
  // should degrade to "backend calls may be blocked", not a blank app, so any
  // failure here is logged and swallowed rather than aborting startup.
  try {
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
  } catch (e) {
    debugPrint('App Check activation failed (continuing without it): $e');
  }

  // Crash reporting, performance, and analytics (Crashlytics/Perf are
  // mobile-only and no-op on web). Best-effort — never block startup on it.
  try {
    await initObservability();
  } catch (e) {
    debugPrint('initObservability failed (continuing): $e');
  }

  // Configure in-app purchases (no-op on web / until RevenueCat keys are set).
  try {
    await PurchasesService().configure();
  } catch (_) {}

  runApp(const ProviderScope(child: MySpotApp()));
}

/// Returns the names of the Firebase config values that are still placeholders
/// (i.e. the matching `--dart-define` / Vercel env var wasn't supplied at build
/// time). An empty list means the config looks fully wired up.
///
/// The map keys are the env var names from scripts/vercel-build.sh / the Vercel
/// project settings, so the startup screen can name exactly what to set.
List<String> _missingFirebaseConfigKeys() {
  final options = DefaultFirebaseOptions.currentPlatform;
  final values = <String, String>{
    'FIREBASE_WEB_API_KEY': options.apiKey,
    'FIREBASE_WEB_APP_ID': options.appId,
    'FIREBASE_MESSAGING_SENDER_ID': options.messagingSenderId,
    'FIREBASE_PROJECT_ID': options.projectId,
    'FIREBASE_AUTH_DOMAIN': options.authDomain ?? '',
    'FIREBASE_STORAGE_BUCKET': options.storageBucket ?? '',
  };
  return values.entries
      .where((e) => e.value.isEmpty || e.value.contains('REPLACE_'))
      .map((e) => e.key)
      .toList(growable: false);
}

/// Shown when the app can't initialize Firebase, instead of a blank page.
///
/// Either [missingKeys] (config never reached the build) or [error] (init threw)
/// is provided. Kept dependency-free — no Firebase, Riverpod, or app router — so
/// it renders even when everything else is broken.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({this.missingKeys = const [], this.error});

  final List<String> missingKeys;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MySpot — configuration needed',
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off,
                      color: Color(0xFF7AA2FF), size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "MySpot can't reach Firebase",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    missingKeys.isNotEmpty
                        ? 'The web build started without its Firebase '
                            'configuration, so the app stops here instead of '
                            'showing a blank screen. Set the variables below in '
                            'Vercel → Project → Settings → Environment Variables '
                            '(Production), then redeploy.'
                        : 'Firebase failed to initialize. The config reached the '
                            'build but Firebase rejected it — double-check the '
                            'values in Vercel match the Firebase web app exactly.',
                    style: const TextStyle(
                      color: Color(0xFFB6C2D9),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (missingKeys.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF24314D)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Missing / placeholder variables:',
                            style: TextStyle(
                              color: Color(0xFF8A98B5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final key in missingKeys)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• $key',
                                style: const TextStyle(
                                  color: Color(0xFFE6ECF7),
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF24314D)),
                      ),
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: Color(0xFFE6ECF7),
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
