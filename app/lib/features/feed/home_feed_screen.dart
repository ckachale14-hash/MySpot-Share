import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/di/repositories.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/post_card.dart';
import '../../features/notifications/push_service.dart';
import '../auth/auth_providers.dart';
import '../notifications/notification_providers.dart';
import '../stories/stories_bar.dart';
import 'feed_providers.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Register this device for push and mark the user online once we're in the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushServiceProvider).registerCurrentDevice();
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid != null) ref.read(presenceServiceProvider).goOnline(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(forYouFeedProvider);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final unread =
        uid == null ? 0 : ref.watch(unreadCountProvider(uid)).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(forYouFeedProvider),
        child: AsyncValueWidget(
          value: feed,
          data: (posts) => CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: StoriesBar()),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              if (posts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyFeed(),
                )
              else
                SliverList.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(post: posts[i]),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/compose'),
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: t.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Your feed is just getting started',
                style: t.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Follow entrepreneurs and share your first post or journey.',
                style: t.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
