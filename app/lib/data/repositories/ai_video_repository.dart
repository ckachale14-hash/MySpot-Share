import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/video_job.dart';

/// Premium AI video generation — request a job and watch its status.
class AiVideoRepository {
  AiVideoRepository(this._db, this._functions);
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<String> requestVideo(String prompt) async {
    final res =
        await _functions.httpsCallable('requestVideo').call({'prompt': prompt});
    return (res.data as Map)['jobId'] as String;
  }

  Stream<List<VideoJob>> watchMyJobs(String uid) => _db
      .collection('videoJobs')
      .where('userId', isEqualTo: uid)
      .limit(30)
      .snapshots()
      .map((q) {
    final list = q.docs.map(VideoJob.fromDoc).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return list;
  });
}
