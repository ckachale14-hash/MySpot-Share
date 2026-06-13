import 'package:firebase_database/firebase_database.dart';

/// Online presence via Realtime Database (`/status/{uid}`), using onDisconnect
/// so "last seen" is reliable even on ungraceful exits.
class PresenceService {
  PresenceService(this._db);
  final FirebaseDatabase _db;

  Future<void> goOnline(String uid) async {
    final ref = _db.ref('status/$uid');
    await ref.onDisconnect().set({
      'online': false,
      'lastSeen': ServerValue.timestamp,
    });
    await ref.set({'online': true, 'lastSeen': ServerValue.timestamp});
  }

  Stream<bool> watchOnline(String uid) =>
      _db.ref('status/$uid/online').onValue.map((e) => e.snapshot.value == true);
}
