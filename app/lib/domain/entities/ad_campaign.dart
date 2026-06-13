import 'package:cloud_firestore/cloud_firestore.dart';

class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.advertiserId,
    this.objective = 'engagement',
    this.status = 'draft',
    this.boostPostId,
    this.budgetTotal = 0,
    this.budgetCurrency = 'NGN',
    this.spent = 0,
    this.impressions = 0,
    this.clicks = 0,
    this.reviewNote,
    this.createdAt,
  });

  final String id;
  final String advertiserId;
  final String objective;
  final String status; // draft | pending_review | active | paused | rejected | completed
  final String? boostPostId;
  final num budgetTotal;
  final String budgetCurrency;
  final num spent;
  final int impressions;
  final int clicks;
  final String? reviewNote;
  final DateTime? createdAt;

  factory AdCampaign.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final budget = (m['budget'] as Map<String, dynamic>?) ?? const {};
    final metrics = (m['metrics'] as Map<String, dynamic>?) ?? const {};
    return AdCampaign(
      id: doc.id,
      advertiserId: (m['advertiserId'] ?? '') as String,
      objective: (m['objective'] ?? 'engagement') as String,
      status: (m['status'] ?? 'draft') as String,
      boostPostId: m['boostPostId'] as String?,
      budgetTotal: (budget['total'] ?? 0) as num,
      budgetCurrency: (budget['currency'] ?? 'NGN') as String,
      spent: (budget['spent'] ?? 0) as num,
      impressions: (metrics['impressions'] ?? 0) as int,
      clicks: (metrics['clicks'] ?? 0) as int,
      reviewNote: m['reviewNote'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
