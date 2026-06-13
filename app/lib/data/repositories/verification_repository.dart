import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/verification_request.dart';

/// User-facing verification: upload KYC docs (to the private `verification/{uid}`
/// path), open a request, and watch its status.
class VerificationRepository {
  VerificationRepository(this._db, this._storage, this._functions);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image and upload it to the caller's private KYC path. Returns the
  /// storage path (not a URL — KYC docs are not publicly readable).
  Future<VerificationDoc?> uploadDoc({required String uid, required String kind}) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 2000);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final path = 'verification/$uid/${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _storage.ref(path).putData(
        bytes, SettableMetadata(contentType: 'image/jpeg'));
    return VerificationDoc(storagePath: path, kind: kind);
  }

  Future<String> startVerification({
    required String subjectType,
    required String subjectId,
    required List<VerificationDoc> documents,
  }) async {
    final res = await _functions.httpsCallable('startVerification').call({
      'subjectType': subjectType,
      'subjectId': subjectId,
      'documents': documents.map((d) => d.toMap()).toList(),
    });
    return (res.data as Map)['requestId'] as String;
  }

  /// The caller's most recent verification request (sorted client-side to avoid
  /// an extra composite index).
  Stream<VerificationRequest?> watchMyLatest(String uid) => _db
      .collection('verificationRequests')
      .where('userId', isEqualTo: uid)
      .limit(10)
      .snapshots()
      .map((q) {
    final list = q.docs.map(VerificationRequest.fromDoc).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list.isEmpty ? null : list.first;
  });
}
