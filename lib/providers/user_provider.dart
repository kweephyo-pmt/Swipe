import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'service_providers.dart';

/// Stream provider for the currently authenticated user's profile
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firestoreServiceProvider).userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
