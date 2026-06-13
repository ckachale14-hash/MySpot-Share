import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/user_avatar.dart';
import 'live_providers.dart';

class LiveDiscoveryScreen extends ConsumerWidget {
  const LiveDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final streams = ref.watch(liveStreamsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live now'),
        actions: [
          IconButton(
            icon: const Icon(Icons.podcasts),
            tooltip: 'Go live',
            onPressed: () => context.push('/live/host'),
          ),
        ],
      ),
      body: streams.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.live_tv_outlined,
                      size: 56, color: t.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('No live streams right now'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.push('/live/host'),
                    icon: const Icon(Icons.podcasts),
                    label: const Text('Go live'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: streams.length,
              itemBuilder: (_, i) {
                final s = streams[i];
                return InkWell(
                  onTap: () => context.push('/live/${s.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14142B), Color(0xFF3D5AFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('LIVE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          const Icon(Icons.visibility,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 2),
                          Text('${s.viewerCount}',
                              style: const TextStyle(color: Colors.white70)),
                        ]),
                        const Spacer(),
                        UserAvatar(
                            photoUrl: s.host.photoUrl,
                            name: s.host.displayName,
                            radius: 18),
                        const SizedBox(height: 6),
                        Text(s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                        Text(s.host.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
