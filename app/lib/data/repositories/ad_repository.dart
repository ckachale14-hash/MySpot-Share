import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/ad_campaign.dart';

/// Advertising: campaigns that boost a post. Funding + approval + metering run
/// through Cloud Functions (server-authoritative); status/metrics are read here.
class AdRepository {
  AdRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<AdCampaign>> watchMyCampaigns(String uid) => _db
      .collection('adCampaigns')
      .where('advertiserId', isEqualTo: uid)
      .limit(50)
      .snapshots()
      .map((q) {
    final list = q.docs.map(AdCampaign.fromDoc).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  });

  Stream<List<AdCampaign>> watchReviewQueue() => _db
      .collection('adCampaigns')
      .where('status', isEqualTo: 'pending_review')
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map(AdCampaign.fromDoc).toList());

  Future<String> createCampaign({
    required String advertiserId,
    required String objective,
    required String boostPostId,
    required num total,
    required String currency,
  }) async {
    final ref = await _db.collection('adCampaigns').add({
      'advertiserId': advertiserId,
      'objective': objective,
      'status': 'draft',
      'boostPostId': boostPostId,
      'budget': {'total': total, 'daily': 0, 'currency': currency, 'spent': 0},
      'metrics': {'impressions': 0, 'clicks': 0},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> fund(String campaignId) async {
    final res = await _functions
        .httpsCallable('initializeAdPayment')
        .call({'campaignId': campaignId});
    return (res.data as Map)['authorizationUrl'] as String;
  }

  Future<void> review(String campaignId, {required bool approve, String? note}) =>
      _functions.httpsCallable('approveCampaign').call({
        'campaignId': campaignId,
        'approve': approve,
        if (note != null) 'note': note,
      });
}
