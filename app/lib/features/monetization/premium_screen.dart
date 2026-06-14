import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../auth/auth_providers.dart';
import 'billing_providers.dart';
import 'purchases_providers.dart';

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
    'AI image & video generation',
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

  /// Web: hosted checkout (Paystack/mobile money).
  Future<void> _subscribeWeb(String plan) async {
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(billingRepositoryProvider)
          .initializePayment(purpose: 'premium', plan: plan);
      await openUrl(url);
      _toast('Complete payment in your browser to activate.');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Mobile: native in-app purchase (RevenueCat). Required by the app stores.
  Future<void> _purchaseMobile(String packageId) async {
    setState(() => _busy = true);
    try {
      final ok = await ref.read(purchasesServiceProvider).purchase(packageId);
      _toast(ok ? 'Premium activated — thank you!' : 'Purchase not completed.');
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
          if (kIsWeb) _webPlans(active) else _mobilePlans(active),
          const SizedBox(height: 8),
          Text(
            kIsWeb
                ? 'Paid securely via card or mobile money.'
                : 'Purchased through the App Store / Google Play. Prices localized per market.',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  // ---- Web: plan cards backed by hosted checkout ----
  Widget _webPlans(bool active) {
    final t = Theme.of(context);
    return Column(
      children: [
        for (final p in _plans)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(p.name, style: t.textTheme.titleLarge)),
                    Text(p.price, style: t.textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 8),
                  for (final perk in p.perks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Icon(Icons.check_circle, size: 18, color: t.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(perk)),
                      ]),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: (_busy || active) ? null : () => _subscribeWeb(p.id),
                    child: Text(active ? 'Active' : 'Subscribe to ${p.name}'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---- Mobile: native IAP packages ----
  Widget _mobilePlans(bool active) {
    final t = Theme.of(context);
    final offerings = ref.watch(offeringsProvider);
    return offerings.when(
      loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Could not load plans: $e'),
      data: (packages) {
        if (packages.isEmpty) {
          // Not configured yet — show plan info, no external checkout on mobile.
          return Column(
            children: [
              for (final p in _plans)
                Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.perks.first),
                    trailing: Text(p.price),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'In-app plans appear here once store products are configured in RevenueCat.'),
              ),
            ],
          );
        }
        return Column(
          children: [
            for (final pkg in packages)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg.title, style: t.textTheme.titleMedium),
                            Text(pkg.priceString, style: t.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed:
                            (_busy || active) ? null : () => _purchaseMobile(pkg.id),
                        child: Text(active ? 'Active' : 'Buy'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
