import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../../domain/entities/verification_request.dart';
import '../auth/auth_providers.dart';
import 'billing_providers.dart';
import 'purchases_providers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<VerificationDoc> _docs = [];
  bool _busy = false;

  Future<void> _upload(String kind) async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final doc =
          await ref.read(verificationRepositoryProvider).uploadDoc(uid: uid, kind: kind);
      if (doc != null) setState(() => _docs.add(doc));
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payAndSubmit() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null || _docs.isEmpty) return;
    setState(() => _busy = true);
    try {
      final requestId =
          await ref.read(verificationRepositoryProvider).startVerification(
                subjectType: 'user',
                subjectId: uid,
                documents: _docs,
              );
      if (kIsWeb) {
        // Web: hosted checkout (card / mobile money).
        final url = await ref.read(billingRepositoryProvider).initializePayment(
              purpose: 'verification',
              relatedId: requestId,
            );
        await openUrl(url);
        _toast('Complete payment in your browser — status updates here.');
      } else {
        // Mobile: native in-app purchase (store policy for digital goods).
        final ok =
            await ref.read(purchasesServiceProvider).purchaseVerification();
        _toast(ok
            ? 'Payment submitted — your verification is under review.'
            : 'In-app purchase unavailable or cancelled.');
      }
      setState(() => _docs.clear());
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
    final req = uid == null ? null : ref.watch(myVerificationProvider(uid)).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Get verified')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (req != null && !req.isPendingPayment) _StatusCard(req: req),
          if (req == null || req.isPendingPayment || req.isRejected) ...[
            Text('The blue tick', style: t.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
                'Verification builds trust, boosts visibility, and unlocks priority '
                'placement. Submit a government ID (and a business document if '
                'verifying a business), then pay the one-time fee. Review begins '
                'after payment is confirmed.'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: t.colorScheme.primary),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Verification fee')),
                    Text(kIsWeb ? '₦5,000' : 'At checkout',
                        style: t.textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Documents (${_docs.length})', style: t.textTheme.titleMedium),
            for (final d in _docs)
              ListTile(
                dense: true,
                leading: const Icon(Icons.description_outlined),
                title: Text(d.kind),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _docs.remove(d)),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _upload('government_id'),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Add ID'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _upload('business_doc'),
                  icon: const Icon(Icons.store_outlined),
                  label: const Text('Add business doc'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: (_busy || _docs.isEmpty) ? null : _payAndSubmit,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                      kIsWeb ? 'Pay ₦5,000 & submit' : 'Submit & pay the fee'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.req});
  final VerificationRequest req;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final (icon, title, body) = switch (req.status) {
      'in_review' => (
          Icons.hourglass_top,
          'Under review',
          'Payment confirmed. Our team is reviewing your documents.'
        ),
      'approved' => (
          Icons.verified,
          'You\'re verified!',
          'Your blue tick is active. Thank you.'
        ),
      _ => (
          Icons.info_outline,
          'Not approved',
          req.reviewNote ?? 'Your application was declined. You can re-apply.'
        ),
    };
    return Card(
      color: t.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: t.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: t.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
