import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/service_providers.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({super.key, required this.user, this.isPreview = false});

  final AppUser user;
  final bool isPreview;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isPreview) {
      return _buildContent(context, widget.user);
    }

    return StreamBuilder<AppUser?>(
      stream: ref.watch(firestoreServiceProvider).userStream(widget.user.uid),
      initialData: widget.user,
      builder: (context, snapshot) {
        final user = snapshot.data ?? widget.user;
        return _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, AppUser user) {
    return Scaffold(
          backgroundColor: const Color(0xFF111115),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Image Section ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main Photo
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      width: double.infinity,
                      child: GestureDetector(
                        onTapUp: (details) {
                          final half = MediaQuery.of(context).size.width / 2;
                          if (details.globalPosition.dx < half) {
                            setState(() => _currentPhotoIndex =
                                (_currentPhotoIndex - 1).clamp(0, user.photoUrls.length - 1));
                          } else {
                            setState(() => _currentPhotoIndex =
                                (_currentPhotoIndex + 1).clamp(0, user.photoUrls.length - 1));
                          }
                        },
                        child: CachedNetworkImage(
                          imageUrl: user.photoUrls.isNotEmpty 
                              ? user.photoUrls[_currentPhotoIndex]
                              : 'https://via.placeholder.com/400x600?text=No+Photo',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),

                    // Photo indicator bars
                    if (user.photoUrls.length > 1)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
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

                    // Floating Arrow Button
                    if (!widget.isPreview)
                      Positioned(
                        bottom: -22,
                        right: 24,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // ── User Information Details ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              '${user.name} ${user.age}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Looking For section
                      const Text(
                        'Looking for',
                        style: TextStyle(
                          color: Color(0xFFAAAABB),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22222D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              user.lookingFor,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // About me section
                      const Text(
                        'About me',
                        style: TextStyle(
                          color: Color(0xFFAAAABB),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.bio.isNotEmpty ? user.bio : "No bio provided.",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFDDDDDD),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.pronouns != null && user.pronouns!.isNotEmpty)
                            _buildInfoChip(Icons.person_outline_rounded, user.pronouns!),
                          if (user.height != null && user.height!.isNotEmpty)
                            _buildInfoChip(Icons.straighten_rounded, user.height!),
                        ],
                      ),                      

                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Text(
                          'Interests',
                          style: TextStyle(
                            color: Color(0xFFAAAABB),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests.map((interest) => _buildInterestChip(interest)).toList(),
                        ),
                      ],

                      const SizedBox(height: 120), // padding for bottom buttons
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22222D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Text(
        interest,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}
