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
            subtitle: 'Host a discussion, launch, or Q&A',
            onTap: () => context.push('/live/host'),
          ),
          _Tile(
            icon: Icons.campaign_outlined,
            title: 'Promote',
            subtitle: 'Boost a post with an ad campaign',
            onTap: () => context.push('/ads'),
          ),
          _Tile(
            icon: Icons.add_business_outlined,
            title: 'List a business',
            subtitle: 'Create a business profile in the directory',
            onTap: () => context.push('/business/new'),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
