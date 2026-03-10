import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_theme.dart';
import '../../models/match.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/service_providers.dart';
import '../shared/skeleton_widgets.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: matchesAsync.when(
          loading: () => const ConversationsSkeletonLoader(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (matches) {
            if (matches.isEmpty) return _buildEmptyState();

            final newMatches = matches
                .where((m) => m.lastMessage == null || m.lastMessage!.isEmpty)
                .toList();
            final conversations = matches
                .where(
                    (m) => m.lastMessage != null && m.lastMessage!.isNotEmpty)
                .toList();

            return CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chat',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 16),
                            Icon(Icons.tune_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── New Matches strip ────────────────────────────────────────
                if (newMatches.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Text(
                        'New matches',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: newMatches.length,
                        itemBuilder: (context, i) => _NewMatchCard(
                          match: newMatches[i],
                          currentUid: currentUid,
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Section divider + label ──────────────────────────────────
                if (conversations.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Messages',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Conversation list ────────────────────────────────────────
                if (conversations.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ConversationTile(
                        match: conversations[i],
                        currentUserId: currentUid,
                      ),
                      childCount: conversations.length,
                    ),
                  ),

                // Prompt when only new matches exist
                if (conversations.isEmpty && newMatches.isNotEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.waving_hand_rounded,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Say hello!',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap a match above to start chatting',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(
            'No messages yet',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Match with someone to start chatting!',
            style:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── New Match Avatar bubble ───────────────────────────────────────────────────

class _NewMatchCard extends ConsumerWidget {
  const _NewMatchCard({
    required this.match,
    required this.currentUid,
  });
  final Match match;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = match.otherUserId(currentUid);
    final otherUserAsync = ref.watch(matchedUserProvider(otherUserId));

    return otherUserAsync.when(
      loading: () => const _AvatarShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => context.push(
            '/chat/${match.matchId}?name=${Uri.encodeComponent(user.name)}&photo=${Uri.encodeComponent(user.firstPhotoUrl)}',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rectangular card with rounded corners
                Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surfaceVariant,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: user.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.firstPhotoUrl,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person_rounded,
                            color: AppColors.textHint, size: 40),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name.split(' ').first,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF00C6FF), size: 14),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarShimmer extends StatelessWidget {
  const _AvatarShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.match,
    required this.currentUserId,
  });
  final Match match;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = match.otherUserId(currentUserId);
    final otherUserAsync = ref.watch(matchedUserProvider(otherUserId));

    return otherUserAsync.when(
      loading: () => const _TileShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final timeStr = match.lastMessageTime != null
            ? timeago.format(match.lastMessageTime!, locale: 'en_short')
            : '';

        return GestureDetector(
          onTap: () => context.push(
            '/chat/${match.matchId}?name=${Uri.encodeComponent(user.name)}&photo=${Uri.encodeComponent(user.firstPhotoUrl)}',
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.surfaceVariant, width: 1)),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: user.photoUrls.isNotEmpty
                      ? CachedNetworkImageProvider(user.firstPhotoUrl)
                      : null,
                  child: user.photoUrls.isEmpty
                      ? const Icon(Icons.person_rounded,
                          color: AppColors.textHint, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),

                // Name + preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF00C6FF), size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            color: AppColors.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              match.lastMessage ?? 'Say hello! 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TileShimmer extends StatelessWidget {
  const _TileShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 110,
                  height: 14,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(5))),
            ],
          ),
        ],
      ),
    );
  }
}
