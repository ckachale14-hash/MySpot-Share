import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

class TrendingTag {
  const TrendingTag(this.tag, this.postCount);
  final String tag;
  final int postCount;
}

/// Discovery surfaces: new users, trending, "people you may know", people search.
/// (Full federated search graduates to Algolia — see docs/06.)
class DiscoveryRepository {
  DiscoveryRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<List<AppUser>> newUsers({int limit = 20}) => _users
      .where('isNewUser', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs.map(AppUser.fromDoc).toList());

  Stream<List<AppUser>> peopleYouMayKnow(String industry, {int limit = 20}) {
    if (industry.isEmpty) return newUsers(limit: limit);
    return _users
        .where('industry', isEqualTo: industry)
        .orderBy('followerCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(AppUser.fromDoc).toList());
  }

  Stream<List<TrendingTag>> trending({int limit = 15}) => _db
      .collection('hashtags')
      .orderBy('score', descending: true)
      .limit(limit)
      .snapshots()
      .map((q) => q.docs
          .map((d) => TrendingTag(
                (d.data()['tag'] ?? d.id) as String,
                (d.data()['postCount'] ?? 0) as int,
              ))
          .toList());

  /// Simple prefix search on @handle (lowercased). Algolia replaces this at scale.
  Future<List<AppUser>> searchPeople(String query, {int limit = 20}) async {
    final q = query.toLowerCase().replaceAll('@', '').trim();
    if (q.isEmpty) return [];
    const high = '\u{f8ff}'; // high Unicode sentinel for prefix range
    final snap = await _users
        .where('handle', isGreaterThanOrEqualTo: q)
        .where('handle', isLessThanOrEqualTo: q + high)
        .limit(limit)
        .get();
    return snap.docs.map(AppUser.fromDoc).toList();
  }
}
