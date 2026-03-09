import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/match.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';
import '../shared/skeleton_widgets.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Matches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
      body: matchesAsync.when(
        loading: () => const MatchesSkeletonLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (matches) {
          if (matches.isEmpty) return _buildEmptyState();
          return CustomScrollView(
            slivers: [
              // "Who Liked You" premium banner
              const SliverToBoxAdapter(child: _LikesBanner()),
              // Matches grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _MatchCard(match: matches[i]),
                    childCount: matches.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const _LikesBanner(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 72, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No matches yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Keep swiping to find your match!', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LikesBanner extends ConsumerWidget {
  const _LikesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final likesAsync = ref.watch(receivedLikesProvider);
    final isPremium = currentUser?.isPremium ?? false;
    final count = likesAsync.valueOrNull?.length ?? 0;

    return GestureDetector(
      onTap: () => context.push('/likes'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Blurred mini avatars of likers
              if (count > 0)
                Positioned.fill(
                  child: Row(
                    children: [
                      ...List.generate(
                        (count > 4 ? 4 : count),
                        (i) {
                          final user = likesAsync.valueOrNull![i];
                          return Expanded(
                            child: SizedBox(
                              height: double.infinity,
                              child: user.photoUrls.isNotEmpty
                                  ? ImageFiltered(
                                      imageFilter: isPremium ? ImageFilter.blur(sigmaX: 0, sigmaY: 0) : ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: CachedNetworkImage(
                                        imageUrl: user.firstPhotoUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(color: AppColors.surfaceVariant),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0F3460).withOpacity(0.6), const Color(0xFF1A1A2E).withOpacity(0.9)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count == 0 ? 'See who likes you' : '$count ${count == 1 ? 'person' : 'people'} liked you!',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPremium ? 'Tap to see their profiles' : 'Upgrade to Gold to see them',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPremium ? 'View' : 'Unlock',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 200.ms),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final otherUserId = match.otherUserId(currentUid);
    final otherUserAsync = ref.watch(matchedUserProvider(otherUserId));

    return otherUserAsync.when(
      loading: () => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push(
            '/chat/${match.matchId}?name=${Uri.encodeComponent(user.name)}&photo=${Uri.encodeComponent(user.firstPhotoUrl)}',
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: user.firstPhotoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.person,
                        color: AppColors.textHint, size: 40),
                  ),
                ),
                const DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: AppColors.cardGradient)),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 12,
                  child: Text(
                    '${user.name}, ${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
