import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_provider.dart';
import '../shared/skeleton_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const ProfileSkeletonLoader(),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return CustomScrollView(
            slivers: [
              // App bar with profile photo
              SliverAppBar(
                backgroundColor: AppColors.background,
                expandedHeight: 360,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      user.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.firstPhotoUrl,
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppColors.surfaceVariant),
                      const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: AppColors.cardGradient)),
                      Positioned(
                        left: 20,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.name}, ${user.age}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (user.locationName != null)
                              Row(children: [
                                Icon(Icons.location_on_rounded,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(user.locationName!,
                                    style: const TextStyle(
                                        color: Colors.white70)),
                              ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.push('/edit-profile'),
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio
                      if (user.bio.isNotEmpty) ...[
                        const Text('About me',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(user.bio,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                height: 1.5)),
                        const SizedBox(height: 24),
                      ],

                      // Info tiles in a single card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surfaceVariant, width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.cake_rounded,
                              label: 'Birthday',
                              value: '${user.birthday.day}/${user.birthday.month}/${user.birthday.year}',
                            ),
                            const Divider(color: AppColors.surfaceVariant, height: 24),
                            _InfoTile(
                              icon: Icons.people_rounded,
                              label: 'Gender',
                              value: user.gender,
                            ),
                            const Divider(color: AppColors.surfaceVariant, height: 24),
                            _InfoTile(
                              icon: Icons.favorite_rounded,
                              label: 'Interested in',
                              value: user.interestedIn,
                            ),
                          ],
                        ),
                        ).animate().fadeIn(duration: 200.ms),

                      const SizedBox(height: 32),
                      Text('Settings',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      // Settings grouped card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surfaceVariant, width: 1),
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.edit_rounded,
                              label: 'Edit Profile',
                              onTap: () => context.push('/edit-profile'),
                            ),
                            const Divider(color: AppColors.surfaceVariant, height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.notifications_rounded,
                              label: 'Notifications',
                              onTap: () {},
                            ),
                            const Divider(color: AppColors.surfaceVariant, height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.privacy_tip_rounded,
                              label: 'Privacy',
                              onTap: () {},
                            ),
                            const Divider(color: AppColors.surfaceVariant, height: 1, indent: 56),
                            _SettingsTile(
                              icon: Icons.help_rounded,
                              label: 'Help & Support',
                              onTap: () {},
                            ),
                          ],
                        ),
                        ).animate().fadeIn(duration: 200.ms),

                      const SizedBox(height: 24),

                      // Danger zone card
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surfaceVariant, width: 1),
                        ),
                        child: _SettingsTile(
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          color: AppColors.dislike,
                          onTap: () => _signOut(context, ref),
                        ),
                        ).animate().fadeIn(duration: 200.ms),

                      const SizedBox(height: 120), // Padding for modern floating bottom map
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign Out',
                  style: TextStyle(color: AppColors.dislike))),
        ],
      ),
    );
    if (confirmed == true) {
      // Just sign out — GoRouter's auth guard will automatically
      // redirect to /login when the auth state stream changes.
      await ref.read(authServiceProvider).signOut();
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
            Text(value,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.textSecondary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color ?? AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.textHint),
    );
  }
}
