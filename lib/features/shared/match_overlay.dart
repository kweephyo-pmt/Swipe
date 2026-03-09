import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';

class MatchOverlay extends StatelessWidget {
  const MatchOverlay({
    super.key,
    required this.matchedUser,
    required this.currentUser,
    required this.matchId,
    required this.onDismiss,
  });

  final AppUser matchedUser;
  final AppUser? currentUser;
  final String matchId;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final safePadding = MediaQuery.of(context).padding;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenH - safePadding.top - safePadding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Overlapping photos ──────────────────────────────
                  SizedBox(
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Current user photo (left, tilted left)
                        Positioned(
                          left: screenW / 2 - 130,
                          top: 70,
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Container(
                              width: 170,
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(-4, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: currentUser != null &&
                                        currentUser!.photoUrls.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: currentUser!.firstPhotoUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(Icons.person_rounded,
                                            color: AppColors.textHint,
                                            size: 64),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Matched user photo (right, slightly higher, tilted right)
                        Positioned(
                          right: screenW / 2 - 130,
                          top: 10,
                          child: Transform.rotate(
                            angle: 0.15,
                            child: Container(
                              width: 170,
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 30,
                                    offset: const Offset(4, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: matchedUser.photoUrls.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: matchedUser.firstPhotoUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(Icons.person_rounded,
                                            color: AppColors.textHint,
                                            size: 64),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Heart badge — bottom-left
                        Positioned(
                          bottom: 15,
                          left: screenW / 2 - 110,
                          child: _HeartBadge(),
                        ),

                        // Heart badge — top-center
                        Positioned(
                          top: -10,
                          left: screenW / 2 - 28,
                          child: _HeartBadge(),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutCubic),

                  const SizedBox(height: 28),

                  // ── Text ────────────────────────────────────────────
                  Text(
                    'CONGRATULATIONS',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 10),

                  Text(
                    "It's a match,\n${currentUser?.name.split(' ').first ?? 'there'}!",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Start a conversation with each other',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),

                  // ── Buttons ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        // Say Hello
                        GestureDetector(
                          onTap: () {
                            onDismiss();
                            context.push(
                              '/chat/$matchId?name=${Uri.encodeComponent(matchedUser.name)}&photo=${Uri.encodeComponent(matchedUser.firstPhotoUrl)}',
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  'Say hello 👋',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 12),

                        // Keep swiping
                        GestureDetector(
                          onTap: onDismiss,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222228),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Keep swiping',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.favorite_rounded, color: AppColors.primary, size: 26),
      ),
    );
  }
}
