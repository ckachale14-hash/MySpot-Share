import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/author_ref.dart';
import '../../domain/entities/founder_journey.dart';

/// Founder Journeys — the platform's signature "how I started" stories.
class JourneyRepository {
  JourneyRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _journeys =>
      _db.collection('founderJourneys');

  Stream<List<FounderJourney>> watchRecent({int limit = 30}) => _journeys
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(FounderJourney.fromDoc).toList());

  Stream<FounderJourney?> watchById(String id) => _journeys
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? FounderJourney.fromDoc(d) : null);

  Future<String> create({
    required AuthorRef author,
    required String title,
    required String industry,
    required JourneyStage stage,
    required num capitalAmount,
    required String capitalCurrency,
    required bool capitalDisclosed,
    List<String> challenges = const [],
    List<String> mistakes = const [],
    List<String> lessons = const [],
  }) async {
    final ref = await _journeys.add({
      'authorId': author.uid,
      'author': author.toMap(),
      'title': title,
      'industry': industry,
      'currentStage': stage.name,
      'startupCapital': {
        'amount': capitalAmount,
        'currency': capitalCurrency,
        'disclosed': capitalDisclosed,
      },
      'timeline': [],
      'challenges': challenges,
      'mistakes': mistakes,
      'lessons': lessons,
      'likeCount': 0,
      'saveCount': 0,
      'viewCount': 0,
      'featured': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
