import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/author_ref.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Direct conversations + messages. Conversation metadata (lastMessage, unread)
/// is maintained by the onMessageCreate Cloud Function.
class ConversationRepository {
  ConversationRepository(this._db);
  final FirebaseFirestore _db;

  String _directId(String a, String b) {
    final s = [a, b]..sort();
    return s.join('_');
  }

  Stream<List<Conversation>> watchConversations(String uid) => _db
      .collection('conversations')
      .where('memberIds', arrayContains: uid)
      .orderBy('updatedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map(Conversation.fromDoc).toList());

  Stream<Conversation?> watchConversation(String cid) => _db
      .doc('conversations/$cid')
      .snapshots()
      .map((d) => d.exists ? Conversation.fromDoc(d) : null);

  Stream<List<Message>> watchMessages(String cid) => _db
      .collection('conversations/$cid/messages')
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots()
      .map((q) => q.docs.map(Message.fromDoc).toList());

  Future<String> getOrCreateDirect(AuthorRef me, AuthorRef other) async {
    final id = _directId(me.uid, other.uid);
    final ref = _db.doc('conversations/$id');
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'memberIds': [me.uid, other.uid],
        'members': {me.uid: me.toMap(), other.uid: other.toMap()},
        'type': 'direct',
        'unread': {me.uid: 0, other.uid: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  /// Create a group conversation owned by [me] with the chosen [others].
  Future<String> createGroup({
    required AuthorRef me,
    required List<AuthorRef> others,
    required String title,
  }) async {
    final members = <String, dynamic>{me.uid: me.toMap()};
    final memberIds = <String>[me.uid];
    final unread = <String, int>{me.uid: 0};
    for (final o in others) {
      members[o.uid] = o.toMap();
      memberIds.add(o.uid);
      unread[o.uid] = 0;
    }
    final ref = await _db.collection('conversations').add({
      'memberIds': memberIds,
      'members': members,
      'type': 'group',
      'title': title,
      'unread': unread,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> sendText(String cid, AuthorRef sender, String text) =>
      _db.collection('conversations/$cid/messages').add({
        'senderId': sender.uid,
        'type': 'text',
        'text': text,
        'readBy': [sender.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> sendImage(String cid, AuthorRef sender, String url) =>
      _db.collection('conversations/$cid/messages').add({
        'senderId': sender.uid,
        'type': 'image',
        'media': {'url': url},
        'readBy': [sender.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

  /// Zero my unread counter and mark the given (others') messages as read.
  Future<void> markRead(String cid, String uid, List<String> otherMessageIds) async {
    final batch = _db.batch();
    batch.update(_db.doc('conversations/$cid'), {'unread.$uid': 0});
    for (final id in otherMessageIds.take(50)) {
      batch.update(_db.doc('conversations/$cid/messages/$id'), {
        'readBy': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
  }
}
