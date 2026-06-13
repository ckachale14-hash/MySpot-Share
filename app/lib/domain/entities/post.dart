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

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.author,
    this.type = PostType.text,
    this.text = '',
    this.media = const [],
    this.hashtags = const [],
    this.visibility = 'public',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
    this.isSponsored = false,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final AuthorRef author;
  final PostType type;
  final String text;
  final List<MediaItem> media;
  final List<String> hashtags;
  final String visibility;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int saveCount;
  final bool isSponsored;
  final DateTime? createdAt;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return Post(
      id: doc.id,
      authorId: (m['authorId'] ?? '') as String,
      author: AuthorRef.fromMap(m['author'] as Map<String, dynamic>?),
      type: _postTypeFromId(m['type'] as String?),
      text: (m['text'] ?? '') as String,
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
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
