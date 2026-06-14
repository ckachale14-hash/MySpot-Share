import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/time_ago.dart';
import '../../domain/entities/app_report.dart';
import 'moderation_providers.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reportQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No open reports 🎉'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [for (final r in items) _ReportCard(report: r)],
              ),
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});
  final AppReport report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  Future<void> _resolve(bool remove) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .resolveReport(widget.report.id, remove: remove);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(remove ? 'Post removed' : 'Report dismissed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('${r.targetType} reported · ${r.reason}',
                      style: Theme.of(context).textTheme.titleSmall)),
              Text(timeAgo(r.createdAt),
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
            Text('Reporter: ${r.reporterId}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                if (r.targetType == 'post')
                  TextButton.icon(
                    onPressed: () => context.push('/post/${r.targetId}'),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View'),
                  ),
                const Spacer(),
                TextButton(
                    onPressed: _busy ? null : () => _resolve(false),
                    child: const Text('Dismiss')),
                const SizedBox(width: 8),
                FilledButton(
                    style:
                        FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _busy ? null : () => _resolve(true),
                    child: const Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
