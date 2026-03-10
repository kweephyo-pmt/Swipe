import 'package:appinio_swiper/appinio_swiper.dart';
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
import 'swipe_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  AppUser? _matchedUser;
  String? _matchedMatchId;
  List<AppUser> _users = [];
  final Set<String> _locallySwipedUids = {};

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _handleSwipe(AppUser swiped, String action) async {
    _locallySwipedUids.add(swiped.uid);
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);

    await firestoreService.recordLike(
      fromUserId: currentUser.uid,
      toUserId: swiped.uid,
      action: action,
    );

    if (action == 'like' || action == 'superLike') {
      final isMatch = await firestoreService.checkMutualLike(
        user1Id: currentUser.uid,
        user2Id: swiped.uid,
      );

      if (isMatch) {
        final matchId = await firestoreService.createMatch(
          user1Id: currentUser.uid,
          user2Id: swiped.uid,
        );
        if (mounted) {
          setState(() {
            _matchedUser = swiped;
            _matchedMatchId = matchId;
          });
        }
      }
    }
  }

  void _swipeLeft() => _swiperController.swipeLeft();
  void _swipeRight() => _swiperController.swipeRight();
  void _swipeUp() => _swiperController.swipeUp();

  @override
  Widget build(BuildContext context) {
    final discoveryAsync = ref.watch(filteredDiscoveryProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final superLikedUids =
        ref.watch(receivedSuperLikesProvider).valueOrNull ?? {};

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── App bar ────────────────────────────────────────────
                _buildTopBar(),

                // ── Card stack ─────────────────────────────────────────
                Expanded(
                  child: discoveryAsync.when(
                    skipLoadingOnRefresh: true,
                    loading: () => const DiscoverySkeletonLoader(),
                    error: (e, _) => Center(
                      child: Text('Error: $e',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ),
                    data: (users) {
                      // Buffer the incoming real-time stream into our local state.
                      // This prevents AppinioSwiper from resetting violently when we swipe
                      // (which shrinks the live stream list). We only append NEW users.
                      if (_users.isEmpty && users.isNotEmpty) {
                        _users = List.of(users);
                      } else {
                        // Check if an external action (e.g., swiping on "Likes You" page)
                        // removed users from the stream that we haven't swiped locally.
                        final streamUids = users.map((u) => u.uid).toSet();
                        final externallyRemoved = _users
                            .where((u) =>
                                !streamUids.contains(u.uid) &&
                                !_locallySwipedUids.contains(u.uid))
                            .toList();

                        if (externallyRemoved.isNotEmpty) {
                          // A user was swiped externally! Force a deck reset so they disappear.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _users.clear();
                                _locallySwipedUids.clear();
                              });
                            }
                          });
                        } else {
                          bool existingUpdated = false;
                          for (int i = 0; i < _users.length; i++) {
                            final idx =
                                users.indexWhere((u) => u.uid == _users[i].uid);
                            if (idx != -1) {
                              final streamUser = users[idx];
                              // Instantly reflect real-time profile edits for users currently in the deck
                              if (_users[i].name != streamUser.name ||
                                  _users[i].bio != streamUser.bio ||
                                  _users[i].age != streamUser.age ||
                                  _users[i].locationName !=
                                      streamUser.locationName ||
                                  _users[i].photoUrls.join(',') !=
                                      streamUser.photoUrls.join(',')) {
                                _users[i] = streamUser;
                                existingUpdated = true;
                              }
                            }
                          }

                          final currentUids = _users.map((e) => e.uid).toSet();
                          final newUsers = users
                              .where((u) => !currentUids.contains(u.uid))
                              .toList();

                          if (newUsers.isNotEmpty || existingUpdated) {
                            // Allow new or updated real-time users to slide into the deck
                            // or refresh existing visible cards
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  if (newUsers.isNotEmpty) {
                                    _users.addAll(newUsers);
                                  }
                                });
                              }
                            });
                          }
                        }
                      }

                      if (_users.isEmpty) return _buildEmptyState();

                      return Stack(
                        children: [
                          Padding(
                            // End right above the visual bottom navbar
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 118),
                            child: AppinioSwiper(
                              controller: _swiperController,
                              cardCount: _users.length,
                              cardBuilder: (context, index) {
                                final u = _users[index];
                                return SwipeCard(
                                  key: ValueKey(u.uid),
                                  user: u,
                                  currentUser: currentUser,
                                  isSuperLiked: superLikedUids.contains(u.uid),
                                  onLike: _swipeRight,
                                  onPass: _swipeLeft,
                                  onSuperLike: _swipeUp,
                                );
                              },
                              onSwipeEnd: (prev, curr, activity) {
                                if (prev < 0 || prev >= _users.length) return;
                                final swiped = _users[prev];
                                String action = 'dislike';
                                if (activity is! Swipe) return;

                                final dir = activity.direction;
                                if (dir == AxisDirection.right) {
                                  action = 'like';
                                } else if (dir == AxisDirection.left) {
                                  action = 'dislike';
                                } else if (dir == AxisDirection.up) {
                                  action = 'superLike';
                                }

                                // ── Intercept super likes if no count left ──
                                if (action == 'superLike') {
                                  final isPremium =
                                      currentUser?.isPremium ?? false;
                                  final count = isPremium
                                      ? currentUser!.superLikesCount
                                      : 0;
                                  if (count <= 0) {
                                    _swiperController.unswipe();
                                    if (isPremium) {
                                      context.push('/buy-super-likes');
                                    } else {
                                      context.push('/premium');
                                    }
                                    return;
                                  }
                                }

                                _handleSwipe(swiped, action);

                                if (curr == _users.length) {
                                  setState(() {
                                    _users.clear();
                                    _locallySwipedUids.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          // ── Action buttons floating on top of card ───────────
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 130, // Safely above the bottom navbar
                            child: _buildActionButtons(currentUser),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Match overlay ──────────────────────────────────────────────
        if (_matchedUser != null && _matchedMatchId != null)
          MatchOverlay(
            matchedUser: _matchedUser!,
            currentUser: ref.watch(currentUserProvider).valueOrNull,
            matchId: _matchedMatchId!,
            onDismiss: () => setState(() {
              _matchedUser = null;
              _matchedMatchId = null;
            }),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Left: Filter Icon
          GestureDetector(
            onTap: _showFilterSheet,
            child: const Icon(Icons.tune_rounded,
                color: AppColors.textPrimary, size: 26),
          ),
          const Spacer(),
          // Right: Lightning
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.flash_on_rounded,
                color: Color(0xFFA334FA), size: 28),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildActionButtons(AppUser? currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo (mock)
          _ActionButton(
            onTap: () {},
            size: 48,
            iconSize: 24,
            color: const Color(0xFF6B7280),
            icon: Icons.replay_rounded,
          ).animate().scale(delay: 50.ms, duration: 200.ms),

          // Dislike
          _ActionButton(
            onTap: _swipeLeft,
            size: 64,
            iconSize: 32,
            color: AppColors.dislike,
            icon: Icons.close_rounded,
          ).animate().scale(delay: 100.ms, duration: 200.ms),

          // Super Like
          _ActionButton(
            onTap: () {
              final isPremium = currentUser?.isPremium ?? false;
              final count = isPremium ? currentUser!.superLikesCount : 0;
              if (count <= 0) {
                if (isPremium) {
                  context.push('/buy-super-likes');
                } else {
                  context.push('/premium');
                }
              } else {
                _swipeUp();
              }
            },
            size: 52,
            iconSize: 26,
            color: const Color(0xFF00C6FF),
            icon: Icons.star_rounded,
          ).animate().scale(delay: 150.ms, duration: 200.ms),

          // Like
          _ActionButton(
            onTap: _swipeRight,
            size: 64,
            iconSize: 32,
            color: const Color(0xFF4DED8E),
            icon: Icons.favorite_rounded,
          ).animate().scale(delay: 200.ms, duration: 200.ms),

          // Send/Boost (mock)
          _ActionButton(
            onTap: () {},
            size: 48,
            iconSize: 24,
            color: const Color(0xFF8B5CF6),
            icon: Icons.send_rounded,
          ).animate().scale(delay: 250.ms, duration: 200.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.explore_off_rounded,
                size: 44, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(
            'No more profiles',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or expand\nyour discovery settings',
            style:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              // Now completely real-time. A tap can force a re-evaluation of the stream if you want,
              // but it's not strictly necessary. Let's just clear the local users to allow re-populating.
              setState(() {
                _users.clear();
                _locallySwipedUids.clear();
              });
              ref.invalidate(filteredDiscoveryProvider);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text('Refresh',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        onApply: () => setState(() {
          _users.clear();
          _locallySwipedUids.clear();
        }),
      ),
    );
  }
}

// ── Nav square button ─────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.size,
    required this.iconSize,
    required this.color,
    required this.icon,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24), // dark card color in reference
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.onApply});
  final VoidCallback onApply;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  int _minAge = 18;
  int _maxAge = 40;
  double _maxDistance = 50;

  @override
  void initState() {
    super.initState();
    // Load current user's actual saved preferences
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _minAge = user.minAgePreference.clamp(18, 99);
      _maxAge = user.maxAgePreference.clamp(18, 99);
      _maxDistance = user.maxDistanceKm.toDouble().clamp(5.0, 500.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extraBottom = MediaQuery.of(context).padding.bottom + 100;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12, 0, extraBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Title row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Discovery Settings',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Age Range ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Age Range',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '$_minAge – $_maxAge',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: RangeSlider(
              values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()),
              min: 18,
              max: 99,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.surfaceVariant,
              onChanged: (v) => setState(() {
                _minAge = v.start.round();
                _maxAge = v.end.round();
              }),
            ),
          ),

          const Divider(
              color: AppColors.surfaceVariant,
              height: 24,
              indent: 24,
              endIndent: 24),

          // ── Maximum Distance ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Maximum Distance',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  _maxDistance.round() >= 500
                      ? 'Worldwide'
                      : '${_maxDistance.round()} km',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: _maxDistance,
              min: 5,
              max: 500,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.surfaceVariant,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ),

          const SizedBox(height: 20),

          // ── Apply button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () async {
                final user = ref.read(currentUserProvider).valueOrNull;
                if (user != null) {
                  await ref
                      .read(firestoreServiceProvider)
                      .updateUser(user.uid, {
                    'minAgePreference': _minAge,
                    'maxAgePreference': _maxAge,
                    'maxDistanceKm': _maxDistance.round(),
                  });
                }
                if (mounted) {
                  Navigator.pop(context);
                  widget.onApply();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Apply Filters',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
