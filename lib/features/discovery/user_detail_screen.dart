import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';
import '../../providers/service_providers.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({
    super.key,
    required this.user,
    this.isPreview = false,
    this.onLike,
    this.onPass,
    this.onSuperLike,
  });

  final AppUser user;
  final bool isPreview;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onSuperLike;

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
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final showActions = widget.onLike != null && widget.onPass != null;

    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────
          Container(
            color: const Color(0xFF111115),
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name + Age
                Text(
                  '${user.name}  ${user.age}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                // Down arrow button
                if (!widget.isPreview)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: Colors.black87, size: 22),
                    ),
                  ),
              ],
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Photo ──────────────────────────────────
                      GestureDetector(
                        onTapUp: (d) {
                          final half =
                              MediaQuery.of(context).size.width / 2;
                          setState(() {
                            if (d.globalPosition.dx < half) {
                              _currentPhotoIndex = (_currentPhotoIndex - 1)
                                  .clamp(0, user.photoUrls.length - 1);
                            } else {
                              _currentPhotoIndex = (_currentPhotoIndex + 1)
                                  .clamp(0, user.photoUrls.length - 1);
                            }
                          });
                        },
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.58,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              user.photoUrls.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          user.photoUrls[_currentPhotoIndex],
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    )
                                  : Container(
                                      color: const Color(0xFF22222D),
                                      child: const Icon(Icons.person_rounded,
                                          size: 80, color: Color(0xFF555566)),
                                    ),

                              // Photo dots top right
                              if (user.photoUrls.length > 1)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        user.photoUrls.length,
                                        (i) => Container(
                                          width: i == _currentPhotoIndex
                                              ? 16
                                              : 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          decoration: BoxDecoration(
                                            color: i == _currentPhotoIndex
                                                ? Colors.white
                                                : Colors.white38,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ── Essentials section ─────────────────────
                      _buildSection(
                        icon: Icons.person_outline_rounded,
                        label: 'Essentials',
                        items: [
                          if (user.locationName != null &&
                              user.locationName!.isNotEmpty)
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              text: user.locationName!,
                            ),
                          if (user.height != null && user.height!.isNotEmpty)
                            _InfoRow(
                              icon: Icons.straighten_rounded,
                              text: user.height!,
                            ),
                          if (user.lookingFor.isNotEmpty)
                            _InfoRow(
                              icon: Icons.favorite_border_rounded,
                              text: user.lookingFor,
                            ),
                          if (user.pronouns != null &&
                              user.pronouns!.isNotEmpty)
                            _InfoRow(
                              icon: Icons.people_outline_rounded,
                              text: user.pronouns!,
                            ),
                        ],
                      ),

                      // ── About / Bio section ───────────────────
                      if (user.bio.isNotEmpty)
                        _buildSection(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'About me',
                          items: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Text(
                                user.bio,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // ── Interests / Lifestyle ─────────────────
                      if (user.interests.isNotEmpty)
                        _buildSection(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Lifestyle',
                          items: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.interests
                                    .map((interest) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E28),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.white12),
                                          ),
                                          child: Text(
                                            interest,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(
                          height: showActions ? 100 + bottomPad : bottomPad + 24),
                    ],
                  ),
                ),

                // ── Floating action buttons ───────────────────────
                if (showActions)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                          40, 16, 40, 20 + bottomPad),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF111115),
                            const Color(0xFF111115).withOpacity(0),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Pass
                          _ActionBtn(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onPass!();
                            },
                            size: 64,
                            bg: const Color(0xFF2A1A1A),
                            border: const Color(0xFFFF4458),
                            child: const Icon(Icons.close_rounded,
                                color: Color(0xFFFF4458), size: 32),
                          ),
                          // Super Like
                          if (widget.onSuperLike != null)
                            _ActionBtn(
                              onTap: () {
                                Navigator.pop(context);
                                widget.onSuperLike!();
                              },
                              size: 54,
                              bg: const Color(0xFF101C2E),
                              border: const Color(0xFF00C6FF),
                              child: const Icon(Icons.star_rounded,
                                  color: Color(0xFF00C6FF), size: 26),
                            ),
                          // Like
                          _ActionBtn(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onLike!();
                            },
                            size: 64,
                            bg: const Color(0xFF0E2018),
                            border: const Color(0xFF3CC66B),
                            child: const Icon(Icons.favorite_rounded,
                                color: Color(0xFF3CC66B), size: 32),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz_rounded,
                    color: Colors.white38, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...items,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: Colors.white10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.onTap,
    required this.size,
    required this.bg,
    required this.border,
    required this.child,
  });
  final VoidCallback onTap;
  final double size;
  final Color bg;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: border.withOpacity(0.25),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
