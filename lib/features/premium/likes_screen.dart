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
    final likesValue = ref.watch(receivedLikesUnmatchedProvider);
    final isPremium = currentUser?.isPremium ?? false;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: likesValue.when(
              loading: () => const LikesSkeletonLoader(),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              data: (likes) {
                return CustomScrollView(
                  slivers: [
                    // ── Header ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Header(
                        isPremium: isPremium,
                        count: likes.length,
                      ).animate().fadeIn(duration: 200.ms),
                    ),

                    if (likes.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyState(isPremium: isPremium),
                      )
                    else ...[
                      // ── Non-premium upgrade bar ──────────────────
                      if (!isPremium)
                        SliverToBoxAdapter(
                          child: _UpgradeBanner(count: likes.length)
                              .animate()
                              .fadeIn(duration: 200.ms),
                        ),

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
                              user: likes[i],
                              isPremium: isPremium,
                              index: i,
                              onLike: () => _likeBack(likes[i]),
                              onPass: () => _pass(likes[i]),
                            ),
                            childCount: likes.length,
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

        // ── Match overlay ────────────────────────────────────────────
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
  const _Header({required this.isPremium, required this.count});
  final bool isPremium;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Likes You',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              if (count > 0)
                Text(
                  '$count ${count == 1 ? 'person likes' : 'people like'} you',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const Spacer(),

          // Premium badge or upgrade button
          if (isPremium)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: Colors.black, size: 14),
                  const SizedBox(width: 4),
                  Text('GOLD',
                      style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => context.push('/premium'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.black, size: 14),
                    const SizedBox(width: 4),
                    Text('Upgrade',
                        style: GoogleFonts.inter(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.user,
    required this.isPremium,
    required this.index,
    required this.onLike,
    required this.onPass,
  });
  final AppUser user;
  final bool isPremium;
  final int index;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPremium
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
            if (!isPremium)
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

            // ── Info ────────────────────────────────────────────
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPremium) ...[
                    Text(
                      '${user.name}, ${user.age}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Like / Pass buttons row
                    Row(
                      children: [
                        _MiniBtn(
                          onTap: onPass,
                          icon: Icons.close_rounded,
                          color: AppColors.dislike,
                        ),
                        const SizedBox(width: 8),
                        _MiniBtn(
                          onTap: onLike,
                          icon: Icons.favorite_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ] else ...[
                    // Gold lock badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFB347)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: Colors.black, size: 11),
                          const SizedBox(width: 3),
                          Text('Unlock',
                              style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── "Likes you" heart badge (premium only) ──────────
            if (isPremium)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 16),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileDetailSheet(
        user: user,
        onLike: onLike,
        onPass: onPass,
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn(
      {required this.onTap, required this.icon, required this.color});
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)
          ],
          border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ── Full profile detail sheet (premium tap) ───────────────────────────────────

class _ProfileDetailSheet extends StatefulWidget {
  const _ProfileDetailSheet({
    required this.user,
    required this.onLike,
    required this.onPass,
  });
  final AppUser user;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  State<_ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<_ProfileDetailSheet> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final h = MediaQuery.of(context).size.height * 0.82;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Photo ────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: GestureDetector(
                onTapUp: (d) {
                  final half = MediaQuery.of(context).size.width / 2;
                  setState(() {
                    if (d.globalPosition.dx < half) {
                      _photoIndex = (_photoIndex - 1)
                          .clamp(0, user.photoUrls.length - 1);
                    } else {
                      _photoIndex = (_photoIndex + 1)
                          .clamp(0, user.photoUrls.length - 1);
                    }
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    user.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrls[_photoIndex],
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.person_rounded,
                                size: 80, color: AppColors.textHint),
                          ),

                    // Gradient
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                      ),
                    ),

                    // Photo dots
                    if (user.photoUrls.length > 1)
                      Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            user.photoUrls.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _photoIndex ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _photoIndex
                                    ? AppColors.primary
                                    : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Name / age
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(user.name,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  )),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('${user.age}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 20,
                                    )),
                              ),
                            ],
                          ),
                          if (user.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(user.bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    color: Colors.white60, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Action row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 16, 40, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pass
                _SheetBtn(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPass();
                  },
                  size: 64,
                  shadowColor: AppColors.dislike,
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.dislike, size: 30),
                ),
                // Like
                _SheetBtn(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onLike();
                  },
                  size: 64,
                  shadowColor: AppColors.primary,
                  child: const Icon(Icons.favorite_rounded,
                      color: AppColors.primary, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  const _SheetBtn(
      {required this.onTap,
      required this.size,
      required this.shadowColor,
      required this.child});
  final VoidCallback onTap;
  final double size;
  final Color shadowColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceVariant, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
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
  const _EmptyState({required this.isPremium});
  final bool isPremium;

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

            Text('No likes yet',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),

            const SizedBox(height: 8),

            Text(
              'Keep swiping — your likes\nwill show up here ✨',
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
