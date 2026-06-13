import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';

enum JourneyStage { idea, mvp, revenue, growth, scaled }

JourneyStage journeyStageFromId(String? id) => JourneyStage.values.firstWhere(
      (s) => s.name == id,
      orElse: () => JourneyStage.idea,
    );

const journeyStageLabels = {
  JourneyStage.idea: 'Idea',
  JourneyStage.mvp: 'MVP',
  JourneyStage.revenue: 'Revenue',
  JourneyStage.growth: 'Growth',
  JourneyStage.scaled: 'Scaled',
};

class FounderJourney {
  const FounderJourney({
    required this.id,
    required this.authorId,
    required this.author,
    this.title = '',
    this.industry = '',
    this.stage = JourneyStage.idea,
    this.capitalAmount = 0,
    this.capitalCurrency = 'USD',
    this.capitalDisclosed = false,
    this.challenges = const [],
    this.mistakes = const [],
    this.lessons = const [],
    this.likeCount = 0,
    this.saveCount = 0,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final AuthorRef author;
  final String title;
  final String industry;
  final JourneyStage stage;
  final num capitalAmount;
  final String capitalCurrency;
  final bool capitalDisclosed;
  final List<String> challenges;
  final List<String> mistakes;
  final List<String> lessons;
  final int likeCount;
  final int saveCount;
  final DateTime? createdAt;

  factory FounderJourney.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final cap = (m['startupCapital'] as Map<String, dynamic>?) ?? const {};
    List<String> strList(dynamic v) =>
        ((v ?? []) as List).map((e) => '$e').toList();
    return FounderJourney(
      id: doc.id,
      authorId: (m['authorId'] ?? '') as String,
      author: AuthorRef.fromMap(m['author'] as Map<String, dynamic>?),
      title: (m['title'] ?? '') as String,
      industry: (m['industry'] ?? '') as String,
      stage: journeyStageFromId(m['currentStage'] as String?),
      capitalAmount: (cap['amount'] ?? 0) as num,
      capitalCurrency: (cap['currency'] ?? 'USD') as String,
      capitalDisclosed: (cap['disclosed'] ?? false) as bool,
      challenges: strList(m['challenges']),
      mistakes: strList(m['mistakes']),
      lessons: strList(m['lessons']),
      likeCount: (m['likeCount'] ?? 0) as int,
      saveCount: (m['saveCount'] ?? 0) as int,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
