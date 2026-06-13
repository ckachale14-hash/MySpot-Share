import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actor,
    this.postId,
    this.text,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String type; // like | comment | follow | mention | system
  final AuthorRef actor;
  final String? postId;
  final String? text;
  final bool read;
  final DateTime? createdAt;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return AppNotification(
      id: doc.id,
      type: (m['type'] ?? 'system') as String,
      actor: AuthorRef.fromMap(m['actor'] as Map<String, dynamic>?),
      postId: m['postId'] as String?,
      text: m['text'] as String?,
      read: (m['read'] ?? false) as bool,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
