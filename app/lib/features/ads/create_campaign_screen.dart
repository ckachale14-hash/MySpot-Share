import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/post.dart';
import '../auth/auth_providers.dart';
import '../feed/feed_providers.dart';

const _objectives = ['awareness', 'traffic', 'engagement', 'leads'];
const _currencies = ['NGN', 'KES', 'GHS', 'ZAR', 'USD'];

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _budget = TextEditingController();
  String _objective = 'engagement';
  String _currency = 'NGN';
  String? _postId;
  bool _busy = false;

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _create(List<Post> posts) async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    final postId = _postId ?? (posts.isNotEmpty ? posts.first.id : null);
    final total = num.tryParse(_budget.text.trim()) ?? 0;
    if (uid == null || postId == null || total <= 0) {
      _toast('Pick a post and enter a budget.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(adRepositoryProvider).createCampaign(
            advertiserId: uid,
            objective: _objective,
            boostPostId: postId,
            total: total,
            currency: _currency,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Draft created — fund it from Ads Manager.')));
      }
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
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final posts =
        uid == null ? <Post>[] : ref.watch(userPostsProvider(uid)).value ?? <Post>[];
    _postId ??= posts.isNotEmpty ? posts.first.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('New campaign')),
      body: posts.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Create a post first — campaigns boost one of your posts.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Boost one of your posts'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _postId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Post'),
                  items: [
                    for (final p in posts)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.text.isEmpty ? '(media post)' : p.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _postId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _objective,
                  decoration: const InputDecoration(labelText: 'Objective'),
                  items: [
                    for (final o in _objectives)
                      DropdownMenuItem(value: o, child: Text(o)),
                  ],
                  onChanged: (v) => setState(() => _objective = v ?? _objective),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _budget,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Total budget'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: [
                          for (final c in _currencies)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? _currency),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : () => _create(posts),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create draft'),
                ),
              ],
            ),
    );
  }
}
