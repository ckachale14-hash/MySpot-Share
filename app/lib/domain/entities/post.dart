import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';
import 'media_item.dart';

enum PostType { text, image, video, article, poll, businessUpdate }

PostType _postTypeFromId(String? id) {
  switch (id) {
    case 'image':
      return PostType.image;
    case 'video':
      return PostType.video;
    case 'article':
      return PostType.article;
    case 'poll':
      return PostType.poll;
    case 'business_update':
      return PostType.businessUpdate;
    default:
      return PostType.text;
  }
}

String postTypeId(PostType t) {
  switch (t) {
    case PostType.image:
      return 'image';
    case PostType.video:
      return 'video';
    case PostType.article:
      return 'article';
    case PostType.poll:
      return 'poll';
    case PostType.businessUpdate:
      return 'business_update';
    case PostType.text:
      return 'text';
  }
}

/// A poll attached to a `type: poll` post. Tallies are maintained server-side
/// by onPollVoteWrite; clients can't write them (firestore.rules).
class Poll {
  const Poll({
    required this.options,
    this.tally = const {},
    this.totalVotes = 0,
    this.closesAt,
  });

  final List<String> options;
  final Map<int, int> tally; // option index -> vote count
  final int totalVotes;
  final DateTime? closesAt;

  int votesFor(int i) => tally[i] ?? 0;
  bool get isClosed => closesAt != null && DateTime.now().isAfter(closesAt!);
  double fractionFor(int i) => totalVotes == 0 ? 0 : votesFor(i) / totalVotes;

  factory Poll.fromMap(Map<String, dynamic> m) {
    final tallyRaw = (m['tally'] as Map<String, dynamic>?) ?? const {};
    final tally = <int, int>{};
    tallyRaw.forEach((k, v) {
      final i = int.tryParse(k);
      if (i != null) tally[i] = (v ?? 0) as int;
    });
    return Poll(
      options: ((m['options'] ?? []) as List).map((e) => '$e').toList(),
      tally: tally,
      totalVotes: (m['totalVotes'] ?? 0) as int,
      closesAt: (m['closesAt'] as Timestamp?)?.toDate(),
    );
  }
}

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.author,
    this.type = PostType.text,
    this.text = '',
    this.title = '',
    this.media = const [],
    this.hashtags = const [],
    this.visibility = 'public',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    this.isSponsored = false,
    this.poll,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final AuthorRef author;
  final PostType type;
  final String text;

  /// Headline for `article` posts (empty otherwise).
  final String title;
  final List<MediaItem> media;
  final List<String> hashtags;
  final String visibility;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int saveCount;
  final bool isSponsored;
  final Poll? poll;
  final DateTime? createdAt;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return Post(
      id: doc.id,
      authorId: (m['authorId'] ?? '') as String,
      author: AuthorRef.fromMap(m['author'] as Map<String, dynamic>?),
      type: _postTypeFromId(m['type'] as String?),
      text: (m['text'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      media: ((m['media'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(MediaItem.fromMap)
          .toList(),
      hashtags: ((m['hashtags'] ?? []) as List).map((e) => '$e').toList(),
      visibility: (m['visibility'] ?? 'public') as String,
      likeCount: (m['likeCount'] ?? 0) as int,
      commentCount: (m['commentCount'] ?? 0) as int,
      shareCount: (m['shareCount'] ?? 0) as int,
      saveCount: (m['saveCount'] ?? 0) as int,
      isSponsored: (m['isSponsored'] ?? false) as bool,
      poll: m['poll'] == null
          ? null
          : Poll.fromMap(Map<String, dynamic>.from(m['poll'] as Map)),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
