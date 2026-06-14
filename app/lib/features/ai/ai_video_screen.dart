import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/open_url.dart';
import '../../core/utils/time_ago.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';
import 'ai_video_providers.dart';

class AiVideoScreen extends ConsumerStatefulWidget {
  const AiVideoScreen({super.key});

  @override
  ConsumerState<AiVideoScreen> createState() => _AiVideoScreenState();
}

class _AiVideoScreenState extends ConsumerState<AiVideoScreen> {
  final _prompt = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_prompt.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(aiVideoRepositoryProvider).requestVideo(_prompt.text.trim());
      _prompt.clear();
      _toast('Queued — we\'ll notify you when it\'s ready.');
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
    final user = ref.watch(appUserProvider).value;
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final premium = user?.premium ?? false;
    final jobs = uid == null ? const [] : ref.watch(myVideoJobsProvider(uid)).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('AI video')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!premium)
            Card(
              color: t.colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: const Text('A Premium feature'),
                subtitle: const Text('Upgrade to generate promotional videos.'),
                trailing: TextButton(
                  onPressed: () => context.push('/premium'),
                  child: const Text('Upgrade'),
                ),
              ),
            ),
          TextField(
            controller: _prompt,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe your video',
              hintText: 'e.g. a 10s promo for a fresh juice brand, upbeat',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (_busy || !premium) ? null : _generate,
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.movie_creation_outlined),
            label: const Text('Generate video'),
          ),
          const Divider(height: 32),
          Text('Your videos', style: t.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (jobs.isEmpty)
            const Text('No videos yet.')
          else
            for (final j in jobs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.movie_outlined),
                title: Text(j.prompt,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${j.status} · ${timeAgo(j.createdAt)}'),
                trailing: j.isReady
                    ? FilledButton.tonal(
                        onPressed: () => openUrl(j.videoUrl!),
                        child: const Text('Watch'),
                      )
                    : (j.status == 'failed'
                        ? const Icon(Icons.error_outline, color: Colors.red)
                        : const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))),
              ),
        ],
      ),
    );
  }
}
