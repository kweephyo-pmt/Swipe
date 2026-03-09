import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';
import '../discovery/user_detail_screen.dart';
import '../shared/match_overlay.dart';
import '../shared/skeleton_widgets.dart';

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  AppUser? _matchedUser;
  String? _matchedMatchId;
  int _selectedTabIndex = 0;

  Future<void> _likeBack(AppUser liker) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final svc = ref.read(firestoreServiceProvider);

    // Record our like — also writes liker.uid to likes/{currentUser.uid},
    // which getDiscoveryUsers uses to filter out already-swiped users.
    await svc.recordLike(
      fromUserId: currentUser.uid,
      toUserId: liker.uid,
      action: 'like',
    );

    // Verify the liker still has an active like on us
    final stillLikesUs = await svc.checkMutualLike(
      user1Id: currentUser.uid,
      user2Id: liker.uid,
    );

    if (!stillLikesUs) {
      // Stale entry — undo our like and clean up
      await svc.recordLike(
        fromUserId: currentUser.uid,
        toUserId: liker.uid,
        action: 'dislike',
      );
      return;
    }

    // Genuinely mutual → create the match
    final matchId = await svc.createMatch(
      user1Id: currentUser.uid,
      user2Id: liker.uid,
    );
    // filteredDiscoveryProvider watches matchesProvider (StreamProvider),
    // so the swipe stack updates automatically — no invalidation needed, no flash.

    if (mounted) {
      setState(() {
        _matchedUser = liker;
        _matchedMatchId = matchId;
      });
    }
  }

  Future<void> _pass(AppUser liker) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    // recordLike(dislike) removes liker from received_likes;
    // StreamProvider picks up the change automatically
    await ref.read(firestoreServiceProvider).recordLike(
      fromUserId: currentUser.uid,
      toUserId: liker.uid,
      action: 'dislike',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isPremium = currentUser?.isPremium ?? false;
    final receivedCount = ref.watch(receivedLikesUnmatchedProvider).valueOrNull?.length ?? 0;

    AsyncValue<List<AppUser>> currentListValue;
    switch (_selectedTabIndex) {
      case 1:
        currentListValue = ref.watch(sentLikesProvider);
        break;
      case 2:
        currentListValue = ref.watch(topPicksProvider);
        break;
      case 0:
      default:
        currentListValue = ref.watch(receivedLikesUnmatchedProvider);
        break;
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: currentListValue.when(
              loading: () => const LikesSkeletonLoader(),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              data: (usersList) {
                return CustomScrollView(
                  slivers: [
                    // ── Header ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Header(
                        isPremium: isPremium,
                        receivedCount: receivedCount,
                        selectedIndex: _selectedTabIndex,
                        onTabChanged: (idx) => setState(() => _selectedTabIndex = idx),
                      ).animate().fadeIn(duration: 200.ms),
                    ),

                    if (usersList.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyState(isPremium: isPremium, tabIndex: _selectedTabIndex),
                      )
                    else ...[
                      // Non-premium upgrade banner removed; using floating action button instead

                      // ── Grid ────────────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 124),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.70,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _LikeCard(
                              user: usersList[i],
                              isPremium: isPremium,
                              index: i,
                              onLike: _selectedTabIndex == 1 ? null : () => _likeBack(usersList[i]),
                              onPass: _selectedTabIndex == 1 ? null : () => _pass(usersList[i]),
                              showFullDetails: _selectedTabIndex != 0, // only require premium on 'Likes You' 
                            ),
                            childCount: usersList.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        
        // Floating action button correctly positioned above the bottom navbar
        if (!isPremium && _selectedTabIndex == 0 && receivedCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 104, // Height of bottom nav + padding
            child: Center(
              child: SizedBox(
                width: 280,
                height: 48,
                child: FloatingActionButton.extended(
                  onPressed: () => context.push('/premium'),
                  backgroundColor: const Color(0xFFE2E4E9),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  label: Text('Upgrade Premium', style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),

        // ── Match overlay ──────────────────────────────────────────────────
        if (_matchedUser != null && _matchedMatchId != null)
          MatchOverlay(
            matchedUser: _matchedUser!,
            currentUser: currentUser,
            matchId: _matchedMatchId!,
            onDismiss: () => setState(() {
              _matchedUser = null;
              _matchedMatchId = null;
            }),
          ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({
    required this.isPremium,
    required this.receivedCount,
    required this.selectedIndex,
    required this.onTabChanged,
  });
  
  final bool isPremium;
  final int receivedCount;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Text(
            'Likes',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
        ),
        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(0),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 0 ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$receivedCount Likes',
                      style: TextStyle(
                        color: selectedIndex == 0 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: Colors.white24),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(1),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 1 ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Likes Sent',
                      style: TextStyle(
                        color: selectedIndex == 1 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: Colors.white24),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged(2),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedIndex == 2 ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Top Picks',
                      style: TextStyle(
                        color: selectedIndex == 2 ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}


// ── Profile card ──────────────────────────────────────────────────────────────

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.user,
    required this.isPremium,
    required this.index,
    this.onLike,
    this.onPass,
    this.showFullDetails = false,
  });
  final AppUser user;
  final bool isPremium;
  final int index;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final bool showFullDetails;

  @override
  Widget build(BuildContext context) {
    final canView = isPremium || showFullDetails;

    return GestureDetector(
      onTap: canView
          ? () => _openDetail(context)
          : () => context.push('/premium'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo ──────────────────────────────────────────────
            user.photoUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: user.firstPhotoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceVariant),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.textHint, size: 48),
                    ),
                  )
                : Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.textHint, size: 48),
                  ),

            // ── Blur for free users ─────────────────────────────
            if (!canView)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: Colors.black.withOpacity(0.05)),
              ),

            // ── Bottom gradient ─────────────────────────────────
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),

            // ── Info (bottom) ───────────────────────────────────
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${user.name}, ${user.age}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('20 hrs left', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFF00C6FF), size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          user: user,
          onLike: onLike,
          onPass: onPass,
        ),
      ),
    );
  }
}



// ── Upgrade banner ────────────────────────────────────────────────────────────

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/premium'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1430), Color(0xFF0F2A50)],
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${count == 1 ? 'person' : 'people'} liked you!',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  Text('Upgrade to see & respond to them',
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('Unlock',
                  style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 350.ms),
    );
  }
}


// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isPremium, this.tabIndex = 0});
  final bool isPremium;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: AppColors.primary, size: 48),
            ).animate().scale(curve: Curves.easeOutCubic, duration: 600.ms),

            const SizedBox(height: 24),

            Text(tabIndex == 0 ? 'No likes yet' : tabIndex == 1 ? 'No sent likes' : 'No top picks today',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),

            const SizedBox(height: 8),

            Text(
              tabIndex == 0 
                  ? 'Keep swiping — your likes\nwill show up here ✨' 
                  : tabIndex == 1 
                      ? "Users you like will appear here"
                      : "Check back later for more picks",
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            if (!isPremium) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => context.push('/premium'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text('Upgrade to Gold',
                          style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}
