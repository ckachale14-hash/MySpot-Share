import 'package:flutter/material.dart';

/// Lightweight placeholders for tabs delivered in later phases (see roadmap).
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: t.colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: t.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
      'Home — For You', 'The FYP feed & stories arrive in Phase P1.', Icons.home);
}

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Discover',
      'Search, people, journeys & trending arrive in Phase P1.', Icons.explore);
}

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('Create',
      'Post / Story / Journey / Live composer arrives in Phase P1–P3.',
      Icons.add_circle);
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder(
      'Messages', 'Realtime chat arrives in Phase P3.', Icons.chat_bubble);
}
