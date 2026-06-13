import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../../domain/entities/ad_campaign.dart';
import '../auth/auth_providers.dart';
import 'ad_providers.dart';

class AdsManagerScreen extends ConsumerWidget {
  const AdsManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final campaigns =
        uid == null ? const [] : ref.watch(myCampaignsProvider(uid)).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ads Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New campaign',
            onPressed: () => context.push('/ads/new'),
          ),
        ],
      ),
      body: campaigns.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 56, color: t.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('No campaigns yet'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/ads/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create a campaign'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [for (final c in campaigns) _CampaignCard(campaign: c)],
            ),
    );
  }
}

class _CampaignCard extends ConsumerWidget {
  const _CampaignCard({required this.campaign});
  final AdCampaign campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    Future<void> fund() async {
      try {
        final url = await ref.read(adRepositoryProvider).fund(campaign.id);
        await openUrl(url);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(campaign.objective.toUpperCase(),
                        style: t.textTheme.labelLarge)),
                Chip(
                  label: Text(campaign.status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Budget: ${campaign.budgetCurrency} ${campaign.budgetTotal}'),
            Text(
                'Impressions ${campaign.impressions} · Clicks ${campaign.clicks}',
                style: t.textTheme.bodySmall),
            if (campaign.status == 'draft')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonal(
                    onPressed: fund, child: const Text('Fund & submit')),
              ),
            if (campaign.status == 'rejected' && campaign.reviewNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Note: ${campaign.reviewNote}',
                    style: t.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
