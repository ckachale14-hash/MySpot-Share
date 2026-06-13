import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

/// Follow graph + reading arbitrary user profiles.
class SocialRepository {
  SocialRepository(this._db);
  final FirebaseFirestore _db;

  String _edgeId(String follower, String following) => '${follower}_$following';

  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Stream<bool> watchFollowing(String me, String target) => _db
      .collection('follows')
      .doc(_edgeId(me, target))
      .snapshots()
      .map((d) => d.exists);

  Future<void> setFollowing(String me, String target, bool follow) {
    final ref = _db.collection('follows').doc(_edgeId(me, target));
    return follow
        ? ref.set({
            'followerId': me,
            'followingId': target,
            'createdAt': FieldValue.serverTimestamp(),
          })
        : ref.delete();
  }
}
