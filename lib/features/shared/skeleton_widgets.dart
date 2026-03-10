import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

// ── Base shimmer wrapper ───────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceVariant,
        highlightColor: const Color(0xFF3A3A50),
        period: const Duration(milliseconds: 1200),
        child: child,
      ),
    );
  }
}

// ── Reusable shimmer box ───────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Discovery – swipe card skeleton ───────────────────────────────────────────

class DiscoverySkeletonLoader extends StatelessWidget {
  const DiscoverySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Shimmer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card body
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            // Bottom info stripe
            Positioned(
              left: 24,
              right: 24,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 28,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 16,
                    width: 110,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            // Distance badge top-left
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                height: 28,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Likes screen – 2-column grid skeleton ─────────────────────────────────────

class LikesSkeletonLoader extends StatelessWidget {
  const LikesSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Header skeleton
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 28, borderRadius: 8),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 14, borderRadius: 6),
                  ],
                ),
                Spacer(),
                ShimmerBox(width: 80, height: 32, borderRadius: 20),
              ],
            ),
          ),
        ),
        // Grid skeleton
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 124),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.70,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => _Shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Matches screen – banner + grid skeleton ───────────────────────────────────

class MatchesSkeletonLoader extends StatelessWidget {
  const MatchesSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Banner skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _Shimmer(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        // Grid skeleton
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => _Shimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Conversations screen skeleton ─────────────────────────────────────────────

class ConversationsSkeletonLoader extends StatelessWidget {
  const ConversationsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // "New Matches" heading
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ShimmerBox(width: 100, height: 18, borderRadius: 6),
          ),
        ),
        // Avatar strip
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Shimmer(
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const ShimmerBox(width: 44, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Divider
        const SliverToBoxAdapter(
          child: Divider(
              color: AppColors.surfaceVariant,
              height: 16,
              indent: 16,
              endIndent: 16),
        ),
        // "Messages" heading
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: ShimmerBox(width: 80, height: 18, borderRadius: 6),
          ),
        ),
        // Conversation tiles
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _Shimmer(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 120, height: 14, borderRadius: 6),
                        SizedBox(height: 8),
                        ShimmerBox(width: 200, height: 12, borderRadius: 5),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const ShimmerBox(width: 40, height: 10, borderRadius: 4),
                ],
              ),
            ),
            childCount: 6,
          ),
        ),
      ],
    );
  }
}

// ── Profile screen skeleton ───────────────────────────────────────────────────

class ProfileSkeletonLoader extends StatelessWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Hero photo skeleton
        SliverAppBar(
          backgroundColor: AppColors.background,
          expandedHeight: 360,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: _Shimmer(
              child: Container(color: AppColors.surfaceVariant),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio block
                const ShimmerBox(width: 80, height: 13, borderRadius: 5),
                const SizedBox(height: 10),
                const ShimmerBox(
                    width: double.infinity, height: 16, borderRadius: 6),
                const SizedBox(height: 6),
                const ShimmerBox(width: 220, height: 16, borderRadius: 6),
                const SizedBox(height: 24),

                // Info card skeleton
                _Shimmer(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: List.generate(
                          3,
                          (i) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                            height: 12,
                                            width: 60,
                                            decoration: BoxDecoration(
                                                color: AppColors.surfaceVariant,
                                                borderRadius:
                                                    BorderRadius.circular(5))),
                                        const SizedBox(height: 6),
                                        Container(
                                            height: 16,
                                            width: 100,
                                            decoration: BoxDecoration(
                                                color: AppColors.surfaceVariant,
                                                borderRadius:
                                                    BorderRadius.circular(6))),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const ShimmerBox(width: 70, height: 13, borderRadius: 5),
                const SizedBox(height: 8),

                // Settings card skeleton
                _Shimmer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: List.generate(
                          4,
                          (i) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                        height: 16,
                                        width: 120,
                                        decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(6))),
                                  ],
                                ),
                              )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
