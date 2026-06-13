import 'package:cloud_firestore/cloud_firestore.dart';

import 'author_ref.dart';

class LiveStream {
  const LiveStream({
    required this.id,
    required this.hostId,
    required this.host,
    this.title = '',
    this.category = '',
    this.status = 'live',
    this.viewerCount = 0,
    this.startedAt,
  });

  final String id;
  final String hostId;
  final AuthorRef host;
  final String title;
  final String category;
  final String status; // scheduled | live | ended
  final int viewerCount;
  final DateTime? startedAt;

  bool get isLive => status == 'live';

  factory LiveStream.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return LiveStream(
      id: doc.id,
      hostId: (m['hostId'] ?? '') as String,
      host: AuthorRef.fromMap(m['host'] as Map<String, dynamic>?),
      title: (m['title'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      status: (m['status'] ?? 'live') as String,
      viewerCount: (m['viewerCount'] ?? 0) as int,
      startedAt: (m['startedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Token bundle returned by the create/join callables (passed to the video SDK).
class LiveCredentials {
  const LiveCredentials({
    required this.streamId,
    required this.channel,
    required this.token,
    required this.appId,
    required this.uid,
  });

  final String streamId;
  final String channel;
  final String token;
  final String appId;
  final int uid;
}
