import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';

class Story {
  const Story({
    required this.id,
    required this.authorId,
    required this.author,
    this.type = 'text',
    this.text = '',
    this.bgColor = 0xFF3D5AFE,
    this.mediaUrl = '',
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String authorId;
  final AuthorRef author;
  final String type; // text | image
  final String text;
  final int bgColor;
  final String mediaUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory Story.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return Story(
      id: doc.id,
      authorId: (m['authorId'] ?? '') as String,
      author: AuthorRef.fromMap(m['author'] as Map<String, dynamic>?),
      type: (m['type'] ?? 'text') as String,
      text: (m['text'] ?? '') as String,
      bgColor: (m['bgColor'] ?? 0xFF3D5AFE) as int,
      mediaUrl: ((m['media'] as Map<String, dynamic>?)?['url'] ?? '') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}
