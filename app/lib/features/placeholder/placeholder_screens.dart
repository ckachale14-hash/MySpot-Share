import 'package:flutter/material.dart';

/// Remaining placeholder for a tab delivered in a later phase (see roadmap).
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: t.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Messages', style: t.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Realtime chat arrives in Phase P3.',
                  textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
