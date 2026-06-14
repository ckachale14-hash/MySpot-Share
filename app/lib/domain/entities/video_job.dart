import 'package:cloud_firestore/cloud_firestore.dart';

class VideoJob {
  const VideoJob({
    required this.id,
    this.prompt = '',
    this.status = 'queued',
    this.videoUrl,
    this.createdAt,
  });

  final String id;
  final String prompt;
  final String status; // queued | processing | ready | failed
  final String? videoUrl;
  final DateTime? createdAt;

  bool get isReady => status == 'ready' && (videoUrl?.isNotEmpty ?? false);

  factory VideoJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return VideoJob(
      id: doc.id,
      prompt: (m['prompt'] ?? '') as String,
      status: (m['status'] ?? 'queued') as String,
      videoUrl: m['videoUrl'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
