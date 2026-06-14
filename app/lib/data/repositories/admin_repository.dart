import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/app_report.dart';
import '../../domain/entities/verification_request.dart';

/// Admin/moderator operations. Authorization is enforced server-side in the
/// callables (this class only triggers them).
class AdminRepository {
  AdminRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<VerificationRequest>> watchReviewQueue() => _db
      .collection('verificationRequests')
      .where('status', isEqualTo: 'in_review')
      .orderBy('updatedAt')
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map(VerificationRequest.fromDoc).toList());

  /// Short-lived signed URL to view a private KYC document.
  Future<String> docUrl(String storagePath) async {
    final res = await _functions
        .httpsCallable('getVerificationDocUrl')
        .call({'path': storagePath});
    return (res.data as Map)['url'] as String;
  }

  Future<void> review(String requestId, {required bool approve, String? note}) =>
      _functions.httpsCallable('approveVerification').call({
        'requestId': requestId,
        'approve': approve,
        if (note != null) 'note': note,
      });

  Stream<List<AppReport>> watchReports() => _db
      .collection('reports')
      .where('status', isEqualTo: 'open')
      .orderBy('createdAt')
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map(AppReport.fromDoc).toList());

  Future<void> resolveReport(String reportId, {required bool remove}) =>
      _functions.httpsCallable('resolveReport').call({
        'reportId': reportId,
        'action': remove ? 'remove' : 'dismiss',
      });
}

