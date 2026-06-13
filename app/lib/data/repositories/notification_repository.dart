import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<AppNotification>> watch(String uid, {int limit = 50}) => _col(uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(AppNotification.fromDoc).toList());

  Stream<int> watchUnreadCount(String uid) =>
      _col(uid).where('read', isEqualTo: false).snapshots().map((q) => q.size);

  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('read', isEqualTo: false).limit(400).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
