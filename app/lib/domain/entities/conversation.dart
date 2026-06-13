import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';

class LastMessage {
  const LastMessage({this.text = '', this.senderId = '', this.type = 'text', this.createdAt});
  final String text;
  final String senderId;
  final String type;
  final DateTime? createdAt;

  factory LastMessage.fromMap(Map<String, dynamic> m) => LastMessage(
        text: (m['text'] ?? '') as String,
        senderId: (m['senderId'] ?? '') as String,
        type: (m['type'] ?? 'text') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}

class Conversation {
  const Conversation({
    required this.id,
    this.memberIds = const [],
    this.members = const {},
    this.type = 'direct',
    this.title = '',
    this.lastMessage,
    this.unread = const {},
    this.updatedAt,
  });

  final String id;
  final List<String> memberIds;
  final Map<String, AuthorRef> members;
  final String type;
  final String title;
  final LastMessage? lastMessage;
  final Map<String, int> unread;
  final DateTime? updatedAt;

  /// The other participant in a direct conversation.
  AuthorRef? other(String myUid) {
    final otherId =
        memberIds.firstWhere((id) => id != myUid, orElse: () => '');
    return members[otherId];
  }

  int unreadFor(String uid) => unread[uid] ?? 0;

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final membersRaw = (m['members'] as Map<String, dynamic>?) ?? const {};
    final members = <String, AuthorRef>{};
    membersRaw.forEach((uid, v) {
      final map = Map<String, dynamic>.from(v as Map);
      map['uid'] = uid;
      members[uid] = AuthorRef.fromMap(map);
    });
    final unreadRaw = (m['unread'] as Map<String, dynamic>?) ?? const {};
    return Conversation(
      id: doc.id,
      memberIds: ((m['memberIds'] ?? []) as List).map((e) => '$e').toList(),
      members: members,
      type: (m['type'] ?? 'direct') as String,
      title: (m['title'] ?? '') as String,
      lastMessage: m['lastMessage'] == null
          ? null
          : LastMessage.fromMap(Map<String, dynamic>.from(m['lastMessage'] as Map)),
      unread: unreadRaw.map((k, v) => MapEntry(k, (v ?? 0) as int)),
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
