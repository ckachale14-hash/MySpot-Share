import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Initializes hosted checkout (Paystack) and reads the user's subscription.
class BillingRepository {
  BillingRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Returns a hosted-checkout URL the client opens. Fulfillment happens in the
  /// payment webhook (the client never grants its own entitlement).
  Future<String> initializePayment({
    required String purpose, // 'verification' | 'premium'
    String? plan,
    String? relatedId,
  }) async {
    final res = await _functions.httpsCallable('initializePayment').call({
      'purpose': purpose,
      if (plan != null) 'plan': plan,
      if (relatedId != null) 'relatedId': relatedId,
    });
    return (res.data as Map)['authorizationUrl'] as String;
  }

  Stream<Map<String, dynamic>?> watchSubscription(String uid) =>
      _db.doc('subscriptions/$uid').snapshots().map((d) => d.data());
}
