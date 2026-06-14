import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/author_ref.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/post.dart';

/// Posts, the For-You feed, likes, saves, and comments.
class PostRepository {
  PostRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');

  Stream<List<Post>> watchForYou({int limit = 20}) => _posts
      .where('visibility', isEqualTo: 'public')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(Post.fromDoc).toList());

  Stream<List<Post>> watchUserPosts(String uid, {int limit = 30}) => _posts
      .where('authorId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(Post.fromDoc).toList());

  Stream<Post?> watchPost(String id) =>
      _posts.doc(id).snapshots().map((d) => d.exists ? Post.fromDoc(d) : null);

  Future<String> createPost({
    required AuthorRef author,
    required PostType type,
    required String text,
    List<MediaItem> media = const [],
    List<String> hashtags = const [],
    List<String> mentions = const [],
    String visibility = 'public',
  }) async {
    final ref = await _posts.add({
      'authorId': author.uid,
      'author': author.toMap(),
      'type': postTypeId(type),
      'text': text,
      'media': media.map((m) => m.toMap()).toList(),
      'hashtags': hashtags,
      'mentions': mentions,
      'visibility': visibility,
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'saveCount': 0,
      'viewCount': 0,
      'score': 0,
      'removed': false,
      'isSponsored': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Create a poll post. Tallies start empty and are maintained server-side.
  Future<String> createPoll({
    required AuthorRef author,
    required String question,
    required List<String> options,
    String visibility = 'public',
    Duration? duration,
  }) async {
    final ref = await _posts.add({
      'authorId': author.uid,
      'author': author.toMap(),
      'type': 'poll',
      'text': question,
      'media': const [],
      'hashtags': const [],
      'mentions': const [],
      'visibility': visibility,
      'poll': {
        'options': options,
        'tally': <String, int>{},
        'totalVotes': 0,
        if (duration != null)
          'closesAt': Timestamp.fromDate(DateTime.now().add(duration)),
      },
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
      'saveCount': 0,
      'viewCount': 0,
      'score': 0,
      'removed': false,
      'isSponsored': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deletePost(String id) => _posts.doc(id).delete();

  // ---- poll votes (one per user at posts/{id}/votes/{uid}; tally by a Function)
  Stream<int?> watchMyVote(String postId, String uid) => _posts
      .doc(postId)
      .collection('votes')
      .doc(uid)
      .snapshots()
      .map((d) {
        final v = d.data()?['option'];
        return v is int ? v : null;
      });

  Future<void> setVote(String postId, String uid, int option) =>
      _posts.doc(postId).collection('votes').doc(uid).set({
        'option': option,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ---- likes (edge at posts/{id}/likes/{uid}; counts maintained by a Function)
  Stream<bool> watchLiked(String postId, String uid) =>
      _posts.doc(postId).collection('likes').doc(uid).snapshots().map((d) => d.exists);

  Future<void> setLiked(String postId, String uid, bool liked) {
    final ref = _posts.doc(postId).collection('likes').doc(uid);
    return liked
        ? ref.set({'createdAt': FieldValue.serverTimestamp()})
        : ref.delete();
  }

  // ---- saves (private bookmark at users/{uid}/saved/{postId})
  Stream<bool> watchSaved(String postId, String uid) => _db
      .doc('users/$uid/saved/$postId')
      .snapshots()
      .map((d) => d.exists);

  Future<void> setSaved(String postId, String uid, bool saved) {
    final ref = _db.doc('users/$uid/saved/$postId');
    return saved
        ? ref.set({'createdAt': FieldValue.serverTimestamp()})
        : ref.delete();
  }

  /// Hydrate the user's bookmarks (users/{uid}/saved) into full posts,
  /// preserving save order and silently dropping any deleted posts.
  Stream<List<Post>> watchSavedPosts(String uid, {int limit = 50}) => _db
      .collection('users')
      .doc(uid)
      .collection('saved')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .asyncMap((q) async {
        final ids = q.docs.map((d) => d.id).toList();
        if (ids.isEmpty) return <Post>[];
        final byId = <String, Post>{};
        for (var i = 0; i < ids.length; i += 10) {
          final end = (i + 10 > ids.length) ? ids.length : i + 10;
          final snap = await _posts
              .where(FieldPath.documentId, whereIn: ids.sublist(i, end))
              .get();
          for (final doc in snap.docs) {
            byId[doc.id] = Post.fromDoc(doc);
          }
        }
        return [for (final id in ids) if (byId[id] != null) byId[id]!];
      });

  // ---- comments
  Stream<List<Comment>> watchComments(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((q) => q.docs.map(Comment.fromDoc).toList());

  Future<void> addComment(String postId, AuthorRef author, String text) =>
      _posts.doc(postId).collection('comments').add({
        'authorId': author.uid,
        'author': author.toMap(),
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteComment(String postId, String commentId) =>
      _posts.doc(postId).collection('comments').doc(commentId).delete();

  Future<void> reportPost(String postId, String reporterId, String reason) =>
      _db.collection('reports').add({
        'reporterId': reporterId,
        'targetType': 'post',
        'targetId': postId,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
}

/// Extract `#hashtags` and `@mentions` (handles) from composer text.
({List<String> hashtags, List<String> mentionHandles}) parseEntities(String text) {
  final tags = RegExp(r'#([a-zA-Z0-9_]{1,50})')
      .allMatches(text)
      .map((m) => m.group(1)!.toLowerCase())
      .toSet()
      .toList();
  final mentions = RegExp(r'@([a-zA-Z0-9_]{3,20})')
      .allMatches(text)
      .map((m) => m.group(1)!.toLowerCase())
      .toSet()
      .toList();
  return (hashtags: tags, mentionHandles: mentions);
}
