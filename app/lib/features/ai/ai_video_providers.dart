import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/video_job.dart';

final myVideoJobsProvider =
    StreamProvider.autoDispose.family<List<VideoJob>, String>(
  (ref, uid) => ref.watch(aiVideoRepositoryProvider).watchMyJobs(uid),
);
