import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/user_provider.dart';
import '../shared/skeleton_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: userAsync.when(
        loading: () => const ProfileSkeletonLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, user, ref),
                  const SizedBox(height: 24),
                  _buildInventoryRow(user),
                  const SizedBox(height: 16),
                  _buildFeaturesList(),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser user, WidgetRef ref) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.grey[900],
          backgroundImage: user.photoUrls.isNotEmpty
              ? CachedNetworkImageProvider(user.firstPhotoUrl)
              : null,
          child: user.photoUrls.isEmpty
              ? const Icon(Icons.person, color: Colors.white, size: 36)
              : null,
        ),
        const SizedBox(width: 16),
        // Name & Edit Profile
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push('/edit-profile'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          color: Colors.black, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Edit profile',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Settings Button
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryRow(AppUser user) {
    int superLikesCount = user.isPremium ? user.superLikesCount : 0;
    if (superLikesCount < 0) superLikesCount = 0; // Prevent negative display

    return Row(
      children: [
        Expanded(
          child: _InventoryCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF00C6FF),
            title: 'Super Like${superLikesCount == 1 ? '' : 's'}',
            count: superLikesCount,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _InventoryCard(
            icon: Icons.bolt_rounded,
            iconColor: Color(0xFFD32BE8),
            title: 'My Boosts',
            subtitle: 'GET MORE',
            subtitleColor: Color(0xFFD32BE8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InventoryCard(
            icon: Icons.fireplace_rounded,
            iconColor: const Color(0xFFFFB000),
            title: 'My Swipe Gold™',
            subtitle: user.isPremium ? 'ACTIVE' : null,
            subtitleColor: const Color(0xFFFFB000),
            showPlus: !user.isPremium,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _FeatureButton(
          icon: Icons.verified_user_rounded,
          iconColor: const Color(0xFF00C6FF),
          title: 'Verify your profile',
          subtitle: 'Get a blue checkmark to stand out',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _FeatureButton(
          icon: Icons.visibility_off_rounded,
          iconColor: const Color(0xFFD32BE8),
          title: 'Incognito Mode',
          subtitle: 'Only be seen by those you like',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _FeatureButton(
          icon: Icons.shield_rounded,
          iconColor: const Color(0xFFFFB000),
          title: 'Safety measures',
          subtitle: 'Tools and guides for a safe experience',
          onTap: () {},
        ),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.count,
    this.subtitle,
    this.subtitleColor,
    this.showPlus = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int? count;
  final String? subtitle;
  final Color? subtitleColor;
  final bool showPlus;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(height: 8),
              if (count != null)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: '$count ',
                    style: GoogleFonts.inter(
                      color: iconColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    color: subtitleColor ?? Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Plus Badge
        if (showPlus)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white54, size: 14),
            ),
          ),
      ],
    );
  }
}

class _FeatureButton extends StatelessWidget {
  const _FeatureButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white54, size: 24),
          ],
        ),
      ),
    );
  }
}
