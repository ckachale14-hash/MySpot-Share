import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/verified_badge.dart';
import '../../domain/entities/founder_journey.dart';
import 'journey_providers.dart';

class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({super.key, required this.journeyId});
  final String journeyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final j = ref.watch(journeyByIdProvider(journeyId)).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Founder Journey')),
      body: j == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(j.title, style: t.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  Chip(label: Text(j.industry)),
                  Chip(label: Text(journeyStageLabels[j.stage]!)),
                  if (j.capitalDisclosed && j.capitalAmount > 0)
                    Chip(
                        avatar: const Icon(Icons.savings_outlined, size: 18),
                        label: Text(
                            'Started with ${j.capitalCurrency} ${j.capitalAmount}')),
                ]),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => context.push('/u/${j.authorId}'),
                  child: Row(children: [
                    UserAvatar(
                        photoUrl: j.author.photoUrl,
                        name: j.author.displayName,
                        radius: 16),
                    const SizedBox(width: 8),
                    Text(j.author.displayName, style: t.textTheme.titleSmall),
                    if (j.author.verified)
                      const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: VerifiedBadge(size: 14)),
                  ]),
                ),
                const Divider(height: 28),
                _list(t, 'Challenges', j.challenges, Icons.terrain_outlined),
                _list(t, 'Mistakes', j.mistakes, Icons.error_outline),
                _list(t, 'Lessons learned', j.lessons, Icons.lightbulb_outline),
              ],
            ),
    );
  }

  Widget _list(ThemeData t, String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: t.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
