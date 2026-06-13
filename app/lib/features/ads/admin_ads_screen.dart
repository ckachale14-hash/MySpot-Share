import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/ad_campaign.dart';
import 'ad_providers.dart';

/// Admin/moderator review queue for funded ad campaigns.
class AdminAdsScreen extends ConsumerWidget {
  const AdminAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(adReviewQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ad review')),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No campaigns awaiting review 🎉'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [for (final c in items) _ReviewCard(campaign: c)],
              ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.campaign});
  final AdCampaign campaign;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _busy = false;

  Future<void> _review(bool approve) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adRepositoryProvider)
          .review(widget.campaign.id, approve: approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(approve ? 'Approved' : 'Rejected')));
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
    final c = widget.campaign;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Objective: ${c.objective}',
                style: Theme.of(context).textTheme.titleSmall),
            Text('Advertiser: ${c.advertiserId}',
                style: Theme.of(context).textTheme.bodySmall),
            Text('Boosting post: ${c.boostPostId ?? "—"}',
                style: Theme.of(context).textTheme.bodySmall),
            Text('Budget: ${c.budgetCurrency} ${c.budgetTotal}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: _busy ? null : () => _review(false),
                    child: const Text('Reject')),
                const SizedBox(width: 8),
                FilledButton(
                    onPressed: _busy ? null : () => _review(true),
                    child: const Text('Approve')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
