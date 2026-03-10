import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/match.dart' as app_match;
import 'discovery_provider.dart';
import 'service_providers.dart';
import 'user_provider.dart';

/// This provider is responsible for listening to matches and triggering
/// local notifications when a new message arrives.
final notificationListenerProvider = Provider<void>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final currentUserId = ref.watch(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null) return;

  // We keep track of the last known message time for each match to
  // only trigger notifications for truly new messages.
  final lastNotifiedTimes = <String, DateTime>{};
  final knownMatchIds = <String>{};
  final knownLikerIds = <String>{};

  // 1. Listen for new Matches & new Messages
  ref.listen<AsyncValue<List<app_match.Match>>>(
    matchesProvider,
    (previous, next) {
      if (next.isLoading || next.hasError) return;

      final matches = next.value ?? [];

      for (final match in matches) {
        // --- NEW MATCH LOGIC ---
        if (previous != null && previous.value != null && !knownMatchIds.contains(match.matchId)) {
          final otherUserId = match.otherUserId(currentUserId);
          ref.read(firestoreServiceProvider).getUser(otherUserId).then((user) {
            final senderName = user?.name ?? 'Someone';
            notificationService.showNotification(
              id: match.matchId.hashCode ^ 1, // Unique ID for match notification
              title: 'New Match! 🔥',
              body: 'You and $senderName liked each other.',
              payload: '/conversations',
            );
          });
        }
        knownMatchIds.add(match.matchId);

        // --- NEW MESSAGE LOGIC ---
        if (match.lastMessageTime == null || match.lastMessage == null)
          continue;

        // If the sender is ourselves, ignore
        if (match.lastMessageSenderId == currentUserId) continue;

        // Has this match's message been notified recently?
        final knownTime = lastNotifiedTimes[match.matchId];

        // Ensure we only notify if it's strictly newer
        if (knownTime == null || match.lastMessageTime!.isAfter(knownTime)) {
          // Avoid spamming on first load: only notify if we already saw the match
          // list at least once (i.e., we have a non-null previous state or if the list wasn't empty)
          if (previous != null &&
              previous.value != null &&
              previous.value!.isNotEmpty) {
            // Get user info to show name using the provider we already have
            final otherUserId = match.otherUserId(currentUserId);

            ref
                .read(firestoreServiceProvider)
                .getUser(otherUserId)
                .then((user) {
              final senderName = user?.name ?? 'Someone';
              final photo = user?.photoUrls.isNotEmpty == true
                  ? user!.photoUrls.first
                  : '';
              final route =
                  '/chat/${match.matchId}?name=${Uri.encodeComponent(senderName)}&photo=${Uri.encodeComponent(photo)}';

              notificationService.showNotification(
                id: match.matchId.hashCode, // Unique ID per match
                title: 'New message from $senderName',
                body: match.lastMessage!,
                payload: route,
              );
            });
          }

          lastNotifiedTimes[match.matchId] = match.lastMessageTime!;
        }
      }
    },
  );

  // 2. Listen for new Likes
  ref.listen<AsyncValue<List<AppUser>>>(
    receivedLikesUnmatchedProvider,
    (previous, next) {
      if (next.isLoading || next.hasError) return;

      final likers = next.value ?? [];

      for (final liker in likers) {
        if (previous != null && previous.value != null && !knownLikerIds.contains(liker.uid)) {
          notificationService.showNotification(
            id: liker.uid.hashCode, 
            title: 'New Like! ❤️',
            body: 'Someone just liked you!',
            payload: '/likes',
          );
        }
        knownLikerIds.add(liker.uid);
      }
    },
  );
});
