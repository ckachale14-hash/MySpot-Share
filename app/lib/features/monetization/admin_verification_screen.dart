import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../../domain/entities/verification_request.dart';
import 'billing_providers.dart';

/// In-app admin/moderator console for the verification review queue.
/// Authorization is enforced server-side by the callables.
class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification review')),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load queue:\n$e',
                    textAlign: TextAlign.center))),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nothing awaiting review 🎉'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [for (final r in items) _ReviewCard(req: r)],
              ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.req});
  final VerificationRequest req;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _busy = false;

  Future<void> _viewDoc(String path) async {
    try {
      final url = await ref.read(adminRepositoryProvider).docUrl(path);
      await openUrl(url);
    } catch (e) {
      _toast('$e');
    }
  }

  Future<void> _review(bool approve) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .review(widget.req.id, approve: approve);
      _toast(approve ? 'Approved' : 'Rejected');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.req;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.subjectType} · ${r.subjectId}',
                style: Theme.of(context).textTheme.titleSmall),
            Text('User: ${r.userId}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in r.documents)
                  ActionChip(
                    avatar: const Icon(Icons.visibility, size: 18),
                    label: Text(d.kind),
                    onPressed: () => _viewDoc(d.storagePath),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => _review(false),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : () => _review(true),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
