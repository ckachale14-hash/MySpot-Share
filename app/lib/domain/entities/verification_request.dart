import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationDoc {
  const VerificationDoc({required this.storagePath, required this.kind});
  final String storagePath;
  final String kind;

  Map<String, String> toMap() => {'storagePath': storagePath, 'kind': kind};

  factory VerificationDoc.fromMap(Map<String, dynamic> m) => VerificationDoc(
        storagePath: (m['storagePath'] ?? '') as String,
        kind: (m['kind'] ?? 'document') as String,
      );
}

/// A verification application. Status is server-driven:
/// pending_payment → in_review → approved | rejected.
class VerificationRequest {
  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.status,
    this.subjectType = 'user',
    this.subjectId = '',
    this.amount = 0,
    this.currency = 'NGN',
    this.reviewNote,
    this.documents = const [],
    this.createdAt,
  });

  final String id;
  final String userId;
  final String status;
  final String subjectType;
  final String subjectId;
  final num amount;
  final String currency;
  final String? reviewNote;
  final List<VerificationDoc> documents;
  final DateTime? createdAt;

  bool get isPendingPayment => status == 'pending_payment';
  bool get isInReview => status == 'in_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory VerificationRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return VerificationRequest(
      id: doc.id,
      userId: (m['userId'] ?? '') as String,
      status: (m['status'] ?? 'pending_payment') as String,
      subjectType: (m['subjectType'] ?? 'user') as String,
      subjectId: (m['subjectId'] ?? '') as String,
      amount: (m['amount'] ?? 0) as num,
      currency: (m['currency'] ?? 'NGN') as String,
      reviewNote: m['reviewNote'] as String?,
      documents: ((m['documents'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(VerificationDoc.fromMap)
          .toList(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
