import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/author_ref.dart';
import '../../domain/entities/live_stream.dart';

typedef LiveChat = ({String id, String senderName, String text});

/// Live streams + live chat. RTC tokens are minted server-side; this client only
/// holds the per-channel token.
class LiveRepository {
  LiveRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<LiveStream>> watchLive() => _db
      .collection('liveStreams')
      .where('status', isEqualTo: 'live')
      .orderBy('viewerCount', descending: true)
      .limit(50)
      .snapshots()
      .map((q) => q.docs.map(LiveStream.fromDoc).toList());

  Stream<LiveStream?> watchStream(String id) => _db
      .doc('liveStreams/$id')
      .snapshots()
      .map((d) => d.exists ? LiveStream.fromDoc(d) : null);

  LiveCredentials _creds(String streamId, Map data) => LiveCredentials(
        streamId: streamId,
        channel: (data['channel'] ?? '') as String,
        token: (data['token'] ?? '') as String,
        appId: (data['appId'] ?? '') as String,
        uid: ((data['uid'] ?? 0) as num).toInt(),
      );

  Future<LiveCredentials> createLive({required String title, String category = ''}) async {
    final res = await _functions
        .httpsCallable('createLiveStream')
        .call({'title': title, 'category': category});
    final d = res.data as Map;
    return _creds((d['streamId'] ?? '') as String, d);
  }

  Future<LiveCredentials> joinLive(String streamId) async {
    final res =
        await _functions.httpsCallable('joinLiveStream').call({'streamId': streamId});
    return _creds(streamId, res.data as Map);
  }

  Future<void> endLive(String streamId) =>
      _functions.httpsCallable('endLiveStream').call({'streamId': streamId});

  Future<void> leaveLive(String streamId) =>
      _functions.httpsCallable('leaveLiveStream').call({'streamId': streamId});

  Stream<List<LiveChat>> watchChat(String id) => _db
      .collection('liveStreams/$id/chat')
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots()
      .map((q) => q.docs
          .map((d) => (
                id: d.id,
                senderName: (d.data()['senderName'] ?? '') as String,
                text: (d.data()['text'] ?? '') as String,
              ))
          .toList());

  Future<void> sendChat(String id, AuthorRef sender, String text) =>
      _db.collection('liveStreams/$id/chat').add({
        'senderId': sender.uid,
        'senderName': sender.displayName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
