import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On Android/iOS the native google-services config provides defaults.
  // Recommended: run `flutterfire configure` to generate firebase_options.dart,
  // then pass `options: DefaultFirebaseOptions.currentPlatform` here.
  await Firebase.initializeApp();

  // App Check gates the backend (callables enforce it). Debug providers are used
  // in debug builds; switch to Play Integrity / DeviceCheck for release.
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

  runApp(const ProviderScope(child: MySpotApp()));
}
