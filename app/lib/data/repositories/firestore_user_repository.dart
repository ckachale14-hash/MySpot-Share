import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/account_type.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  @override
  Future<String> claimHandle(String handle) async {
    final res =
        await _functions.httpsCallable('claimHandle').call({'handle': handle});
    return (res.data as Map)['handle'] as String;
  }

  @override
  Future<void> completeOnboarding({
    required String uid,
    required String displayName,
    required AccountType accountType,
    required String industry,
    String bio = '',
  }) async {
    await _db.collection('users').doc(uid).update({
      'displayName': displayName,
      'accountType': accountType.id,
      'industry': industry,
      'bio': bio,
      'onboardingComplete': true,
    });
  }
}
