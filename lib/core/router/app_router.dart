import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/conversations_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_flow.dart';
import '../../features/premium/likes_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/premium/buy_super_likes_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';

// Notifies GoRouter to re-evaluate redirect whenever auth or user state changes
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);

      // Still loading — don't redirect yet
      if (authAsync.isLoading || userAsync.isLoading) return null;

      final isLoggedIn = authAsync.valueOrNull != null;
      final loc = state.matchedLocation;
      final isOnAuthPage = loc == '/login' || loc == '/register';

      // Not logged in → force to login
      if (!isLoggedIn) {
        return isOnAuthPage ? null : '/login';
      }

      // Logged in — check onboarding
      final onboardingDone =
          userAsync.valueOrNull?.isOnboardingComplete ?? false;

      if (!onboardingDone) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      // Fully onboarded — redirect away from auth/onboarding pages
      if (isOnAuthPage || loc == '/onboarding') {
        return '/discovery';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discovery',
                builder: (context, state) => const DiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/likes',
                builder: (context, state) => const LikesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conversations',
                builder: (context, state) => const ConversationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final otherUserName = state.uri.queryParameters['name'] ?? '';
          final otherUserPhoto = state.uri.queryParameters['photo'] ?? '';
          return ChatScreen(
            matchId: matchId,
            otherUserName: otherUserName,
            otherUserPhotoUrl: otherUserPhoto,
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: '/buy-super-likes',
        builder: (context, state) => const BuySuperLikesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
