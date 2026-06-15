import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/di/repositories.dart';
import '../../core/widgets/post_card.dart';
import '../../features/notifications/push_service.dart';
import '../auth/auth_providers.dart';
import '../monetization/purchases_providers.dart';
import '../notifications/notification_providers.dart';
import '../stories/stories_bar.dart';
import 'feed_controller.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Register this device for push and mark the user online once we're in the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushServiceProvider).registerCurrentDevice();
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid != null) {
        ref.read(presenceServiceProvider).goOnline(uid);
        ref.read(purchasesServiceProvider).identify(uid);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 600) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final unread =
        uid == null ? 0 : ref.watch(unreadCountProvider(uid)).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: 'Live',
            onPressed: () => context.push('/live'),
            icon: const Icon(Icons.live_tv_outlined),
          ),
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
        onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            const SliverToBoxAdapter(child: StoriesBar()),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            if (feed.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (feed.error != null && feed.posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load your feed.\n${feed.error}',
                        textAlign: TextAlign.center),
                  ),
                ),
              )
            else if (feed.posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyFeed(),
              )
            else ...[
              SliverList.builder(
                itemCount: feed.posts.length,
                itemBuilder: (_, i) => PostCard(post: feed.posts[i]),
              ),
              SliverToBoxAdapter(
                child: _FeedFooter(
                    loadingMore: feed.isLoadingMore, hasMore: feed.hasMore),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/compose'),
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.loadingMore, required this.hasMore});
  final bool loadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
            child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text("You're all caught up",
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    return const SizedBox(height: 24);
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
