import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_providers.dart';

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(
    FirebaseMessaging.instance,
    ref.watch(functionsProvider),
    ref.watch(firebaseAuthProvider),
  ),
);

/// Requests notification permission, obtains the FCM token, and registers it on
/// the user's private profile via the `registerDevice` callable (the token can't
/// be written to the private collection directly — it's server-only).
class PushService {
  PushService(this._messaging, this._functions, this._auth);

  final FirebaseMessaging _messaging;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  bool _wired = false;

  Future<void> registerCurrentDevice() async {
    if (_auth.currentUser == null) return;
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null) await _register(token);

      if (!_wired) {
        _wired = true;
        _messaging.onTokenRefresh.listen(_register);
      }
    } catch (e) {
      debugPrint('PushService: registration skipped: $e');
    }
  }

  Future<void> _register(String token) =>
      _functions.httpsCallable('registerDevice').call({'token': token});
}
