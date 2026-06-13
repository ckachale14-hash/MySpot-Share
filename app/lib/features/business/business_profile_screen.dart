import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/rating_stars.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/verified_badge.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';
import 'business_providers.dart';

class BusinessProfileScreen extends ConsumerWidget {
  const BusinessProfileScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final b = ref.watch(businessProvider(id)).value;
    final reviews = ref.watch(businessReviewsProvider(id)).value ?? const [];
    final myUid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(b?.name ?? 'Business'),
        actions: [
          if (b != null && b.ownerId == myUid)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/business/${b.id}/edit'),
            ),
        ],
      ),
      body: b == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    UserAvatar(photoUrl: b.logoUrl, name: b.name, radius: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                                child: Text(b.name,
                                    style: t.textTheme.titleLarge,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis)),
                            if (b.verified)
                              const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: VerifiedBadge()),
                          ]),
                          if (b.category.isNotEmpty)
                            Text(b.category,
                                style: t.textTheme.bodyMedium
                                    ?.copyWith(color: t.colorScheme.primary)),
                          RatingStars(rating: b.ratingAvg, count: b.ratingCount),
                        ],
                      ),
                    ),
                  ],
                ),
                if (b.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(b.description),
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    if (b.phone.isNotEmpty)
                      _ContactChip(
                          icon: Icons.call,
                          label: 'Call',
                          onTap: () => openUrl('tel:${b.phone}')),
                    if (b.whatsapp.isNotEmpty)
                      _ContactChip(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          onTap: () => openUrl(
                              'https://wa.me/${b.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}')),
                    if (b.email.isNotEmpty)
                      _ContactChip(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          onTap: () => openUrl('mailto:${b.email}')),
                    if (b.website.isNotEmpty)
                      _ContactChip(
                          icon: Icons.language,
                          label: 'Website',
                          onTap: () => openUrl(_https(b.website))),
                  ],
                ),
                if (b.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b.address)),
                    ]),
                  ),
                _chips(t, 'Products', b.products),
                _chips(t, 'Services', b.services),
                const Divider(height: 32),
                Text('Reviews', style: t.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (myUid != null && myUid != b.ownerId)
                  _ReviewComposer(businessId: id),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No reviews yet', style: t.textTheme.bodyMedium),
                  ),
                for (final r in reviews)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(
                        photoUrl: r.authorPhotoUrl,
                        name: r.authorName,
                        radius: 16),
                    title: Row(children: [
                      Expanded(child: Text(r.authorName)),
                      RatingStars(rating: r.rating, size: 14),
                    ]),
                    subtitle: Text(r.text),
                    trailing: Text(timeAgo(r.createdAt),
                        style: t.textTheme.bodySmall),
                  ),
              ],
            ),
    );
  }

  String _https(String url) =>
      url.startsWith('http') ? url : 'https://$url';

  Widget _chips(ThemeData t, String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final i in items) Chip(label: Text(i)),
          ]),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      );
}

class _ReviewComposer extends ConsumerStatefulWidget {
  const _ReviewComposer({required this.businessId});
  final String businessId;

  @override
  ConsumerState<_ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends ConsumerState<_ReviewComposer> {
  final _text = TextEditingController();
  int _rating = 5;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final author = ref.read(currentAuthorRefProvider);
    if (author == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(businessRepositoryProvider).submitReview(
          widget.businessId, author, _rating, _text.text.trim());
      _text.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Review submitted')));
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Your rating: '),
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(i <= _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFB300)),
                    onPressed: () => setState(() => _rating = i),
                  ),
              ],
            ),
            TextField(
              controller: _text,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Share your experience…'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: const Text('Post review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
