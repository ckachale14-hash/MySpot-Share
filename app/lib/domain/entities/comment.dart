import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';

class Comment {
  const Comment({
    required this.id,
    required this.authorId,
    required this.author,
    this.text = '',
    this.createdAt,
  });

  final String id;
  final String authorId;
  final AuthorRef author;
  final String text;
  final DateTime? createdAt;

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return Comment(
      id: doc.id,
      authorId: (m['authorId'] ?? '') as String,
      author: AuthorRef.fromMap(m['author'] as Map<String, dynamic>?),
      text: (m['text'] ?? '') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
