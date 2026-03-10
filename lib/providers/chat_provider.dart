import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import 'service_providers.dart';

final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, matchId) {
  return ref.watch(firestoreServiceProvider).messagesStream(matchId);
});
