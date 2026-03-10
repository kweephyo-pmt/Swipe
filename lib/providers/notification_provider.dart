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
  
  // Record exactly when this provider was spun up (e.g. on hot restart)
  final providerStartTime = DateTime.now();

  // 1. Listen for new Matches & new Messages
  ref.listen<AsyncValue<List<app_match.Match>>>(
    matchesProvider,
    (previous, next) {
      if (next.isLoading || next.hasError) return;

      final matches = next.value ?? [];

      for (final match in matches) {
        // --- NEW MATCH LOGIC ---
        if (!knownMatchIds.contains(match.matchId)) {
          knownMatchIds.add(match.matchId);
          
          // Only notify if the match was definitely created after the app started
          if (match.timestamp.isAfter(providerStartTime)) {
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
        }

        // --- NEW MESSAGE LOGIC ---
        if (match.lastMessageTime == null || match.lastMessage == null) {
          continue;
        }

        // If the sender is ourselves, ignore
        if (match.lastMessageSenderId == currentUserId) continue;

        // Has this match's message been notified recently?
        final knownTime = lastNotifiedTimes[match.matchId];

        // Ensure we only notify if it's strictly newer
        if (knownTime == null || match.lastMessageTime!.isAfter(knownTime)) {
          lastNotifiedTimes[match.matchId] = match.lastMessageTime!;

          // Only notify if the message was actually sent after the app started!
          // This absolutely prevents past messages from triggering notifications on hot restart.
          if (match.lastMessageTime!.isAfter(providerStartTime)) {
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
        if (!knownLikerIds.contains(liker.uid)) {
          knownLikerIds.add(liker.uid);
          
          // For likes, we don't fetch the timestamp currently.
          // Block notifications for the first 3 seconds after a hot restart to swallow the initial state load.
          if (DateTime.now().difference(providerStartTime).inSeconds > 3) {
            notificationService.showNotification(
              id: liker.uid.hashCode, 
              title: 'New Like! ❤️',
              body: 'Someone just liked you!',
              payload: '/likes',
            );
          }
        }
      }
    },
  );
});
