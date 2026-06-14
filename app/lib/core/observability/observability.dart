import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Shared Analytics instance and a go_router navigation observer that logs
/// screen_view events. Analytics is supported on web and mobile.
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver analyticsObserver =
    FirebaseAnalyticsObserver(analytics: analytics);

/// Route crashes and uncaught errors to Crashlytics, and enable Performance
/// Monitoring. Crashlytics/Performance have no web support, so on web this is
/// a no-op (analytics still works via [analyticsObserver]).
Future<void> initObservability() async {
  if (kIsWeb) return;

  // Don't report noise from local debug runs.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  await FirebasePerformance.instance
      .setPerformanceCollectionEnabled(!kDebugMode);

  // Framework + async errors → Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
