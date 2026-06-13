import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/author_ref.dart';
import '../../domain/entities/story.dart';

/// 24h ephemeral stories. Expiry is enforced by a Firestore TTL policy on
/// `expiresAt`; queries also filter by it so expired-but-not-yet-reaped docs
/// don't show.
class StoryRepository {
  StoryRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _stories =>
      _db.collection('stories');

  Stream<List<Story>> watchActive({int limit = 50}) => _stories
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(Story.fromDoc).toList());

  Stream<List<Story>> watchByAuthor(String uid) => _stories
      .where('authorId', isEqualTo: uid)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map(Story.fromDoc).toList());

  Future<void> createTextStory({
    required AuthorRef author,
    required String text,
    required int bgColor,
  }) {
    final now = DateTime.now();
    return _stories.add({
      'authorId': author.uid,
      'author': author.toMap(),
      'type': 'text',
      'text': text,
      'bgColor': bgColor,
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });
  }

  Future<void> createImageStory({
    required AuthorRef author,
    required String mediaUrl,
  }) {
    final now = DateTime.now();
    return _stories.add({
      'authorId': author.uid,
      'author': author.toMap(),
      'type': 'image',
      'media': {'url': mediaUrl},
      'viewCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
    });
  }

  Future<void> recordView(String storyId, String uid) => _stories
      .doc(storyId)
      .collection('views')
      .doc(uid)
      .set({'createdAt': FieldValue.serverTimestamp()});
}
