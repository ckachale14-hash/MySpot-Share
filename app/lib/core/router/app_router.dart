import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../observability/observability.dart';
import '../../features/ads/admin_ads_screen.dart';
import '../../features/ads/ads_manager_screen.dart';
import '../../features/ads/create_campaign_screen.dart';
import '../../features/ai/ai_video_screen.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/business/business_directory_screen.dart';
import '../../features/business/business_editor_screen.dart';
import '../../features/business/business_profile_screen.dart';
import '../../features/create/create_hub_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/invite/invite_screen.dart';
import '../../features/live/host_live_screen.dart';
import '../../features/live/live_discovery_screen.dart';
import '../../features/live/live_viewer_screen.dart';
import '../../features/feed/article_editor_screen.dart';
import '../../features/feed/composer_screen.dart';
import '../../features/feed/home_feed_screen.dart';
import '../../features/feed/post_detail_screen.dart';
import '../../features/feed/saved_posts_screen.dart';
import '../../features/journeys/journey_detail_screen.dart';
import '../../features/journeys/journey_editor_screen.dart';
import '../../features/messaging/chat_screen.dart';
import '../../features/messaging/conversations_screen.dart';
import '../../features/messaging/new_group_screen.dart';
import '../../features/messaging/new_message_screen.dart';
import '../../features/moderation/moderation_screen.dart';
import '../../features/monetization/admin_verification_screen.dart';
import '../../features/monetization/premium_screen.dart';
import '../../features/monetization/verification_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/profile_setup_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/user_providers.dart';
import '../../features/shell/root_shell.dart';
import '../../features/social/blocked_accounts_screen.dart';
import '../../features/social/user_profile_screen.dart';
import '../../features/stories/story_composer_screen.dart';
import '../../features/stories/story_viewer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [analyticsObserver],
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const ProfileSetupScreen()),

      // Full-screen routes pushed above the tab shell.
      GoRoute(path: '/compose', builder: (_, __) => const ComposerScreen()),
      GoRoute(
          path: '/article/new',
          builder: (_, __) => const ArticleEditorScreen()),
      GoRoute(
          path: '/post/:id',
          builder: (_, s) => PostDetailScreen(postId: s.pathParameters['id']!)),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/journey/new', builder: (_, __) => const JourneyEditorScreen()),
      GoRoute(
          path: '/journey/:id',
          builder: (_, s) =>
              JourneyDetailScreen(journeyId: s.pathParameters['id']!)),
      GoRoute(path: '/story/compose', builder: (_, __) => const StoryComposerScreen()),
      GoRoute(
          path: '/story/:authorId',
          builder: (_, s) =>
              StoryViewerScreen(authorId: s.pathParameters['authorId']!)),
      GoRoute(
          path: '/u/:uid',
          builder: (_, s) => UserProfileScreen(uid: s.pathParameters['uid']!)),

      // Business directory
      GoRoute(path: '/businesses', builder: (_, __) => const BusinessDirectoryScreen()),
      GoRoute(path: '/business/new', builder: (_, __) => const BusinessEditorScreen()),
      GoRoute(
          path: '/business/:id/edit',
          builder: (_, s) =>
              BusinessEditorScreen(businessId: s.pathParameters['id'])),
      GoRoute(
          path: '/b/:id',
          builder: (_, s) => BusinessProfileScreen(id: s.pathParameters['id']!)),

      GoRoute(path: '/invite', builder: (_, __) => const InviteScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/settings/blocked',
          builder: (_, __) => const BlockedAccountsScreen()),
      GoRoute(path: '/saved', builder: (_, __) => const SavedPostsScreen()),

      // Monetization (P2)
      GoRoute(path: '/verify', builder: (_, __) => const VerificationScreen()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
      GoRoute(
          path: '/admin/verifications',
          builder: (_, __) => const AdminVerificationScreen()),

      // Messaging (P3)
      GoRoute(path: '/messages/new', builder: (_, __) => const NewMessageScreen()),
      GoRoute(
          path: '/messages/new-group',
          builder: (_, __) => const NewGroupScreen()),
      GoRoute(
          path: '/chat/:cid',
          builder: (_, s) => ChatScreen(cid: s.pathParameters['cid']!)),

      // Live streaming (P3)
      GoRoute(path: '/live', builder: (_, __) => const LiveDiscoveryScreen()),
      GoRoute(path: '/live/host', builder: (_, __) => const HostLiveScreen()),
      GoRoute(
          path: '/live/:id',
          builder: (_, s) => LiveViewerScreen(streamId: s.pathParameters['id']!)),

      // Advertising (P3)
      GoRoute(path: '/ads', builder: (_, __) => const AdsManagerScreen()),
      GoRoute(path: '/ads/new', builder: (_, __) => const CreateCampaignScreen()),
      GoRoute(path: '/admin/ads', builder: (_, __) => const AdminAdsScreen()),
      GoRoute(path: '/admin/reports', builder: (_, __) => const ModerationScreen()),

      // AI video (P3)
      GoRoute(path: '/ai/video', builder: (_, __) => const AiVideoScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => RootShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeFeedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/create', builder: (_, __) => const CreateHubScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/messages', builder: (_, __) => const ConversationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(appUserProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateChangesProvider);
    if (authState.isLoading || authState.hasError) return null;

    final loggedIn = authState.value != null;
    final loc = state.matchedLocation;
    final atSignIn = loc == '/sign-in';

    if (!loggedIn) return atSignIn ? null : '/sign-in';

    final user = _ref.read(appUserProvider).value;
    final atOnboarding = loc == '/onboarding';
    if (user != null && !user.onboardingComplete) {
      return atOnboarding ? null : '/onboarding';
    }
    if (atSignIn || atOnboarding) return '/home';
    return null;
  }
}
