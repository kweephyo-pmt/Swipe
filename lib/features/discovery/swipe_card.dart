import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import 'user_detail_screen.dart';

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.user,
    required this.currentUser,
    this.isSuperLiked = false,
    this.onLike,
    this.onPass,
    this.onSuperLike,
    this.swipeOffsetNotifier,
  });

  final AppUser user;
  final AppUser? currentUser;
  final bool isSuperLiked;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onSuperLike;
  final ValueNotifier<Offset>? swipeOffsetNotifier;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: GestureDetector(
        onTapUp: (details) {
          HapticFeedback.lightImpact();
          final half = MediaQuery.of(context).size.width / 2;
          if (details.globalPosition.dx < half) {
            setState(() => _currentPhotoIndex =
                (_currentPhotoIndex - 1).clamp(0, user.photoUrls.length - 1));
          } else {
            setState(() => _currentPhotoIndex =
                (_currentPhotoIndex + 1).clamp(0, user.photoUrls.length - 1));
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Solid background to prevent bottom cards from showing during cross-fades ──
            Container(color: AppColors.surfaceVariant),
            // ── Background photo ───────────────────────────────────────
            CachedNetworkImage(
              imageUrl: user.photoUrls.isNotEmpty
                  ? user.photoUrls[_currentPhotoIndex]
                  : 'https://via.placeholder.com/400x600?text=No+Photo',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (_, __) => Container(
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.person_rounded,
                    color: AppColors.textHint, size: 80),
              ),
            ),

            // ── Photo indicator bars (top) ─────────────────────────────
            if (user.photoUrls.length > 1)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(
                    user.photoUrls.length,
                    (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == _currentPhotoIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Dark gradient overlay (bottom heavy) ───────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.5, 0.7, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // ── User info (bottom) ─────────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 90, // Positioned safely inside the card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active status & Super Liked indicator
                  Row(
                    children: [
                      // Active status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0C8A4F),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.isSuperLiked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Super Liked You',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name, Age and Up Arrow button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '${user.name}  ${user.age}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      // Expand profile button (Up Arrow)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(
                                user: user,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_upward_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bio
                  if (user.bio.isNotEmpty) ...[
                    Text(
                      user.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Dynamic Stamps (Like / Dislike) ────────────────────────
            if (widget.swipeOffsetNotifier != null)
              Positioned.fill(
                child: ValueListenableBuilder<Offset>(
                  valueListenable: widget.swipeOffsetNotifier!,
                  builder: (context, offset, child) {
                    final dx = offset.dx;
                    final dy = offset.dy;
                    if (dx == 0 && dy == 0) return const SizedBox.shrink();

                    // Dislike (Swipe Left or Down)
                    if (dx < -20 || dy > 20 && dx.abs() < 20) {
                      final opacity = (dx.abs() / 100).clamp(0.0, 1.0);
                      return Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Transform.rotate(
                            angle: 0.2,
                            child: Opacity(
                              opacity: opacity,
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFFFF2A6D),
                                size: 120,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // Like (Swipe Right)
                    if (dx > 20) {
                      final opacity = (dx / 100).clamp(0.0, 1.0);
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Opacity(
                              opacity: opacity,
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFF4DED8E),
                                size: 120,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Super Like (Swipe Up)
                    if (dy < -20 && dx.abs() < 20) {
                      final opacity = (dy.abs() / 100).clamp(0.0, 1.0);
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 250.0),
                          child: Transform.rotate(
                            angle: -0.1,
                            child: Opacity(
                              opacity: opacity,
                              child: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFF00C6FF),
                                size: 100,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
