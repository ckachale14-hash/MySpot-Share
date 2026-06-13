import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../profile/user_providers.dart';

class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final user = ref.watch(appUserProvider).value;
    final code = (user?.handle.isNotEmpty ?? false) ? user!.handle : (user?.uid ?? '');
    final link = 'https://myspot.app/i/$code';
    final message =
        'Join me on MySpot — where entrepreneurs connect and grow. $link';

    return Scaffold(
      appBar: AppBar(title: const Text('Invite friends')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.group_add_outlined, size: 56, color: t.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Grow the community', style: t.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'Invite entrepreneurs, customers, and investors. Share your link via '
              'WhatsApp, Facebook, Instagram, SMS, or email — your invites are tracked '
              'so you get credit when they join.'),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              title: Text(link),
              subtitle: const Text('Your invite link'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Share.share(message, subject: 'Join me on MySpot'),
            icon: const Icon(Icons.share),
            label: const Text('Share invite'),
          ),
          const SizedBox(height: 8),
          Text(
            'Deferred deep links + referral attribution are wired with Branch '
            '(see docs/06) so installs from this link land in the right place and '
            'count toward your referrals.',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
