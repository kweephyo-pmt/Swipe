import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/match.dart';
import 'service_providers.dart';
import 'user_provider.dart';

// ── Core Streams ──────────────────────────────────────────────────────────

final _allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).usersStream();
});

final _swipedIdsStreamProvider =
    StreamProvider.family<Set<String>, String>((ref, uid) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return Stream.value({});
  return ref.watch(firestoreServiceProvider).swipedIdsStream(uid);
});

// ── Discovery / Swipe ─────────────────────────────────────────────────────

// Reactively combines the live users and live swiped interactions
final discoveryUsersProvider = Provider<AsyncValue<List<AppUser>>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return const AsyncValue.loading();

  final usersAsync = ref.watch(_allUsersStreamProvider);
  final swipedIdsAsync = ref.watch(_swipedIdsStreamProvider(currentUser.uid));

  if (usersAsync.isLoading || swipedIdsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (usersAsync.hasError) {
    return AsyncValue.error(usersAsync.error!, StackTrace.empty);
  }
  if (swipedIdsAsync.hasError) {
    return AsyncValue.error(swipedIdsAsync.error!, StackTrace.empty);
  }

  final allUsers = usersAsync.valueOrNull ?? [];
  final swipedIds = swipedIdsAsync.valueOrNull ?? {};

  String? genderFilter;
  if (currentUser.interestedIn == 'Women') genderFilter = 'Woman';
  if (currentUser.interestedIn == 'Men') genderFilter = 'Man';

  final list = allUsers.where((u) {
    if (u.uid == currentUser.uid) return false;
    if (swipedIds.contains(u.uid)) return false;
    if (u.age < currentUser.minAgePreference ||
        u.age > currentUser.maxAgePreference) return false;
    if (genderFilter != null && u.gender != genderFilter) return false;

    // Haversine distance calculation
    if (currentUser.location != null && u.location != null) {
      final lat1 = currentUser.location!.latitude * pi / 180;
      final lon1 = currentUser.location!.longitude * pi / 180;
      final lat2 = u.location!.latitude * pi / 180;
      final lon2 = u.location!.longitude * pi / 180;

      final dlat = lat2 - lat1;
      final dlon = lon2 - lon1;

      final a = sin(dlat / 2) * sin(dlat / 2) +
          cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));

      const earthRadiusKm = 6371.0;
      final distance = earthRadiusKm * c;

      if (distance > currentUser.maxDistanceKm) return false;
    }

    return true;
  }).toList();

  return AsyncValue.data(list);
});

// ── Matches (real-time stream) ────────────────────────────────────────────

final matchesProvider = StreamProvider<List<Match>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(firestoreServiceProvider).matchesStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ── Discovery users — filtered against live matches ───────────────────────
//
// Combining discoveryUsersProvider (FutureProvider) with matchesProvider
// (StreamProvider) means: whenever a match is created anywhere in the app,
// this provider recomputes and removes the matched person from the swipe stack
// without any invalidation or flash.
final filteredDiscoveryProvider = Provider<AsyncValue<List<AppUser>>>((ref) {
  final discoveryAsync = ref.watch(discoveryUsersProvider);
  final matchesAsync = ref.watch(matchesProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;

  if (discoveryAsync.isLoading) return const AsyncValue.loading();
  if (discoveryAsync.hasError) {
    return AsyncValue.error(discoveryAsync.error!, StackTrace.empty);
  }

  final users = discoveryAsync.valueOrNull ?? [];
  final matches = matchesAsync.valueOrNull ?? [];

  if (uid == null || matches.isEmpty) return AsyncValue.data(users);

  final matchedIds = matches.map((m) => m.otherUserId(uid)).toSet();
  final filtered = users.where((u) => !matchedIds.contains(u.uid)).toList();

  return AsyncValue.data(filtered);
});

// ── Liked user for match dialog ───────────────────────────────────────────
final matchedUserProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  return ref.watch(firestoreServiceProvider).getUser(userId);
});

// ── Who liked me — real-time stream ──────────────────────────────────────
//
// Uses receivedLikesStream() so the Likes You page updates instantly
// whenever someone likes or unlikes you, without any manual refresh.
final receivedLikesProvider = StreamProvider<List<AppUser>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).receivedLikesStream(uid);
});

final receivedSuperLikesProvider = StreamProvider<Set<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value({});
  return ref.watch(firestoreServiceProvider).receivedSuperLikesStream(uid);
});

// ── Who liked me — filtered: removes already-matched users ───────────────
//
// Combines receivedLikesProvider (StreamProvider) and matchesProvider
// (StreamProvider) so filtering is always up-to-date.
final receivedLikesUnmatchedProvider =
    Provider<AsyncValue<List<AppUser>>>((ref) {
  final likesAsync = ref.watch(receivedLikesProvider);
  final matchesAsync = ref.watch(matchesProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;

  if (likesAsync.isLoading || matchesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (likesAsync.hasError) {
    return AsyncValue.error(likesAsync.error!, StackTrace.empty);
  }
  if (matchesAsync.hasError) {
    return AsyncValue.error(matchesAsync.error!, StackTrace.empty);
  }

  final likers = likesAsync.valueOrNull ?? [];
  final matches = matchesAsync.valueOrNull ?? [];

  if (uid == null || likers.isEmpty) return AsyncValue.data(likers);

  final matchedIds = matches.map((m) => m.otherUserId(uid)).toSet();
  final filtered = likers.where((u) => !matchedIds.contains(u.uid)).toList();

  return AsyncValue.data(filtered);
});

// ── Likes Sent ────────────────────────────────────────────────────────────
final sentLikesProvider = StreamProvider<List<AppUser>>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).sentLikesStream(uid);
});

// ── Top Picks ─────────────────────────────────────────────────────────────
final topPicksProvider = Provider<AsyncValue<List<AppUser>>>((ref) {
  final discoveryAsync = ref.watch(filteredDiscoveryProvider);
  return discoveryAsync.whenData((users) {
    // Return up to 10 random users (simulated top picks)
    final list = users.toList()..shuffle(Random());
    return list.take(10).toList();
  });
});
