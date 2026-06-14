import 'package:cloud_firestore/cloud_firestore.dart';

class AppReport {
  const AppReport({
    required this.id,
    required this.reporterId,
    this.targetType = 'post',
    this.targetId = '',
    this.reason = '',
    this.status = 'open',
    this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime? createdAt;

  factory AppReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return AppReport(
      id: doc.id,
      reporterId: (m['reporterId'] ?? '') as String,
      targetType: (m['targetType'] ?? 'post') as String,
      targetId: (m['targetId'] ?? '') as String,
      reason: (m['reason'] ?? '') as String,
      status: (m['status'] ?? 'open') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
