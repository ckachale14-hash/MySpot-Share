import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../auth/auth_providers.dart';
import 'billing_providers.dart';

class _PlanInfo {
  const _PlanInfo(this.id, this.name, this.price, this.perks);
  final String id;
  final String name;
  final String price;
  final List<String> perks;
}

const _plans = [
  _PlanInfo('pro', 'Pro', '₦2,500 / mo', [
    'Verified badge included',
    'Higher AI quotas',
    'Advanced analytics',
    'Priority placement',
  ]),
  _PlanInfo('business', 'Business', '₦10,000 / mo', [
    'Everything in Pro',
    'AI image generation',
    'Audience insights',
    'Self-serve Ads Manager',
  ]),
];

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;

  Future<void> _subscribe(String plan) async {
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(billingRepositoryProvider)
          .initializePayment(purpose: 'premium', plan: plan);
      await openUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Complete payment in your browser to activate.')));
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
    final t = Theme.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final sub = uid == null ? null : ref.watch(subscriptionProvider(uid)).value;
    final active = sub != null && sub['status'] == 'active';

    return Scaffold(
      appBar: AppBar(title: const Text('MySpot Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (active)
            Card(
              color: t.colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text('You\'re on ${sub['plan'] ?? 'Premium'}'),
                subtitle: Text('Status: ${sub['status']}'),
              ),
            )
          else
            Text('Grow faster with Premium', style: t.textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final p in _plans)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(p.name, style: t.textTheme.titleLarge)),
                        Text(p.price, style: t.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final perk in p.perks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Icon(Icons.check_circle,
                              size: 18, color: t.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(perk)),
                        ]),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: (_busy || active) ? null : () => _subscribe(p.id),
                      child: Text(active ? 'Active' : 'Subscribe to ${p.name}'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'On mobile, premium is also available via Play/App Store billing. '
            'Prices are localized per market.',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
