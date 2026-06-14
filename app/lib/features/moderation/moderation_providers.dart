import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/app_report.dart';

final reportQueueProvider = StreamProvider.autoDispose<List<AppReport>>(
  (ref) => ref.watch(adminRepositoryProvider).watchReports(),
);
