import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The "Create" tab — a hub that routes to each composer.
class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _Tile(
            icon: Icons.edit_outlined,
            title: 'New Post',
            subtitle: 'Share an update, idea, or win',
            onTap: () => context.push('/compose'),
          ),
          _Tile(
            icon: Icons.auto_stories_outlined,
            title: 'Founder Journey',
            subtitle: 'Tell how you started — capital, mistakes, lessons',
            onTap: () => context.push('/journey/new'),
          ),
          _Tile(
            icon: Icons.amp_stories_outlined,
            title: 'Story',
            subtitle: 'A 24-hour update or announcement',
            onTap: () => context.push('/story/compose'),
          ),
          _Tile(
            icon: Icons.live_tv_outlined,
            title: 'Go Live',
            subtitle: 'Host a discussion or Q&A (coming in P3)',
            enabled: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withOpacity(enabled ? 1 : 0.4),
      child: ListTile(
        enabled: enabled,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
