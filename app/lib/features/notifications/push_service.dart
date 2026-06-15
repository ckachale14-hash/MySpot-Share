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
  bool _tapWired = false;

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

  /// Wire notification taps to navigation. Handles both a cold start from a
  /// tapped notification (getInitialMessage) and taps while backgrounded
  /// (onMessageOpenedApp). [onOpen] receives the message's data payload.
  void wireTapToOpen(void Function(Map<String, dynamic> data) onOpen) {
    if (_tapWired) return;
    _tapWired = true;
    _messaging.getInitialMessage().then((m) {
      if (m != null) onOpen(m.data);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(m.data));
  }

  Future<void> _register(String token) =>
      _functions.httpsCallable('registerDevice').call({'token': token});
}

/// Maps an FCM data payload to an in-app route, or null when none applies.
/// (FCM coerces all data values to strings.)
String? pushTargetPath(Map<String, dynamic> data) {
  switch (data['type']) {
    case 'message':
      final cid = data['conversationId'];
      return (cid is String && cid.isNotEmpty) ? '/chat/$cid' : null;
    case 'like':
    case 'comment':
    case 'mention':
      final pid = data['postId'];
      return (pid is String && pid.isNotEmpty) ? '/post/$pid' : null;
    case 'follow':
      final uid = data['actorUid'];
      return (uid is String && uid.isNotEmpty) ? '/u/$uid' : null;
    default:
      return null;
  }
}
