import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/onboarding/profile_setup_screen.dart';
import '../../features/placeholder/placeholder_screens.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/user_providers.dart';
import '../../features/shell/root_shell.dart';

/// go_router wired to auth + onboarding state. The redirect funnels users to
/// /sign-in when signed out, /onboarding until their profile is complete, and
/// the tab shell otherwise.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const ProfileSetupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => RootShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/create', builder: (_, __) => const CreateScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
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
