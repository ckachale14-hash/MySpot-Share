import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  const Message({
    required this.id,
    required this.senderId,
    this.type = 'text',
    this.text = '',
    this.mediaUrl = '',
    this.readBy = const [],
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String type; // text | image
  final String text;
  final String mediaUrl;
  final List<String> readBy;
  final DateTime? createdAt;

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return Message(
      id: doc.id,
      senderId: (m['senderId'] ?? '') as String,
      type: (m['type'] ?? 'text') as String,
      text: (m['text'] ?? '') as String,
      mediaUrl: ((m['media'] as Map<String, dynamic>?)?['url'] ?? '') as String,
      readBy: ((m['readBy'] ?? []) as List).map((e) => '$e').toList(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
