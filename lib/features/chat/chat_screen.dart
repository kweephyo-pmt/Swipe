import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/discovery_provider.dart';
import '../../providers/service_providers.dart';
import '../discovery/user_detail_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.otherUserId,
  });

  final String matchId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String otherUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });

    // Mark messages as read when entering the chat
    Future.microtask(() {
      if (mounted) {
        ref.read(firestoreServiceProvider).markMessagesRead(widget.matchId);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    HapticFeedback.lightImpact();
    _msgCtrl.clear();

    final message = Message(
      messageId: '',
      senderId: uid,
      text: text,
      timestamp: DateTime.now(),
    );

    await ref
        .read(firestoreServiceProvider)
        .sendMessage(matchId: widget.matchId, message: message);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to matches provider to auto-pop if the match is deleted
    ref.listen(matchesProvider, (previous, next) {
      if (!next.isLoading && !next.hasError) {
        final matches = next.valueOrNull ?? [];
        final hasMatch = matches.any((m) => m.matchId == widget.matchId);
        if (!hasMatch && mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/discovery');
          }
        }
      }
    });

    final messagesAsync = ref.watch(messagesProvider(widget.matchId));
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();

                // Mark messages as read if the last message wasn't from us
                if (messages.isNotEmpty &&
                    messages.first.senderId != currentUid) {
                  Future.microtask(() {
                    if (mounted) {
                      ref
                          .read(firestoreServiceProvider)
                          .markMessagesRead(widget.matchId);
                    }
                  });
                }

                // Group messages by date
                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUid;

                    // Show date separator when date changes or gap > 60 mins
                    final prevMsg =
                        (i + 1 < messages.length) ? messages[i + 1] : null;
                    final showDate = prevMsg == null ||
                        msg.timestamp.difference(prevMsg.timestamp).inMinutes >
                            60 ||
                        !_isSameDay(msg.timestamp, prevMsg.timestamp);

                    // Show avatar when sender changes
                    final showAvatar = !isMe &&
                        (i == 0 || messages[i - 1].senderId != msg.senderId);

                    return Column(
                      children: [
                        if (showDate) _DateChip(date: msg.timestamp),
                        _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: showAvatar,
                          photoUrl: widget.otherUserPhotoUrl,
                          isLast: i == 0,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────────────────
          _InputBar(
            controller: _msgCtrl,
            focusNode: _focusNode,
            hasText: _hasText,
            onSend: _sendMessage,
            bottomPadding: bottomPadding,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Avatar + name centered (clickable)
              GestureDetector(
                onTap: () async {
                  if (widget.otherUserId.isEmpty) return;
                  
                  // Optimistically show loading maybe, but the fetch is usually fast enough
                  final user = await ref.read(firestoreServiceProvider).getUser(widget.otherUserId);
                  if (user != null && mounted) {
                    Navigator.of(context, rootNavigator: true).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => UserDetailScreen(user: user),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(position: animation.drive(tween), child: child);
                        },
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: widget.otherUserPhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(widget.otherUserPhotoUrl)
                          : null,
                      child: widget.otherUserPhotoUrl.isEmpty
                          ? const Icon(Icons.person_rounded,
                              color: AppColors.textHint, size: 22)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.otherUserName,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Back button on the left
              Positioned(
                left: 6,
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/discovery');
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // More button on the right
              Positioned(
                right: 12,
                child: PopupMenuButton<String>(
                  color: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  offset: const Offset(0, 40),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  onSelected: (value) async {
                    if (value == 'unmatch') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'Unmatch ${widget.otherUserName}?',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to unmatch? This action cannot be undone, and your conversation will be deleted forever.',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Unmatch',
                                style: GoogleFonts.inter(
                                  color: AppColors.dislike,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref
                            .read(firestoreServiceProvider)
                            .unmatch(widget.matchId);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'unmatch',
                      child: Row(
                        children: [
                          const Icon(Icons.person_remove_rounded,
                              color: AppColors.dislike, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Unmatch',
                            style: GoogleFonts.inter(
                              color: AppColors.dislike,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile photo
            if (widget.otherUserPhotoUrl.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4458), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      CachedNetworkImageProvider(widget.otherUserPhotoUrl),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.otherUserName,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You matched with ${widget.otherUserName.split(' ').first}! 🎉\nSay something nice to break the ice.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Quick-reply chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickReply(
                  label: 'Hey there! 👋',
                  onTap: () {
                    _msgCtrl.text = 'Hey there! 👋';
                    setState(() => _hasText = true);
                    _focusNode.requestFocus();
                  },
                ),
                _QuickReply(
                  label: "What's up? 😊",
                  onTap: () {
                    _msgCtrl.text = "What's up? 😊";
                    setState(() => _hasText = true);
                    _focusNode.requestFocus();
                  },
                ),
                _QuickReply(
                  label: 'Nice to meet you!',
                  onTap: () {
                    _msgCtrl.text = 'Nice to meet you!';
                    setState(() => _hasText = true);
                    _focusNode.requestFocus();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.hasText,
    required this.onSend,
    required this.bottomPadding,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasText;
  final VoidCallback onSend;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // GIF Button
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Text(
              'GIF',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary, fontSize: 15),
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textHint, fontSize: 15),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (hasText)
                    GestureDetector(
                      onTap: onSend,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_circle_up_rounded,
                          color: Color(0xFF0084FF),
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.photoUrl,
    this.isLast = false,
  });

  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String photoUrl;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(20);
    const tightRadius = Radius.circular(4);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 6,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Other user's avatar
              if (!isMe) ...[
                if (showAvatar)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person_rounded,
                            color: AppColors.textHint, size: 16)
                        : null,
                  )
                else
                  const SizedBox(width: 32),
                const SizedBox(width: 8),
              ],

              // Bubble
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF0084FF)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: radius,
                      topRight: radius,
                      bottomLeft: isMe ? radius : tightRadius,
                      bottomRight: isMe ? tightRadius : radius,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isMe && isLast) ...[
            const SizedBox(height: 4),
            Text(
              'Sent',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ── Date separator chip ────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  String _label() {
    return DateFormat("d MMM 'at' h:mm a").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Center(
        child: Text(
          _label(),
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Quick reply chip ───────────────────────────────────────────────────────────

class _QuickReply extends StatelessWidget {
  const _QuickReply({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
