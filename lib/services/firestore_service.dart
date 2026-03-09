import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/match.dart';
import '../models/message.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── USER ──────────────────────────────────────────────────────────────────

  Future<void> createUser(AppUser user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> userStream(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Future<void> updateLastSeen(String uid) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'lastSeen': FieldValue.serverTimestamp()});
  }

  // ── DISCOVERY (Streams) ───────────────────────────────────────────────────

  /// Real-time stream of all valid discovery users (up to a reasonable limit)
  Stream<List<AppUser>> usersStream() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('isOnboardingComplete', isEqualTo: true)
        .limit(150)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  /// Real-time stream of UIDs the current user has already swiped on (likes/dislikes)
  Stream<Set<String>> swipedIdsStream(String currentUserId) {
    return _db
        .collection(AppConstants.likesCollection)
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      final swipedIds = <String>{currentUserId}; // Exclude self
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        swipedIds.addAll(data.keys);
      }
      return swipedIds;
    });
  }

  Future<void> recordLike({
    required String fromUserId,
    required String toUserId,
    required String action, // 'like', 'superLike', 'dislike'
  }) async {
    final batch = _db.batch();

    // Write swipe action to the likes collection
    batch.set(
      _db.collection(AppConstants.likesCollection).doc(fromUserId),
      {toUserId: action},
      SetOptions(merge: true),
    );

    if (action == 'like' || action == 'superLike') {
      // Record in received_likes so the other user can see who liked them
      batch.set(
        _db.collection('received_likes').doc(toUserId),
        {
          fromUserId: {
            'timestamp': FieldValue.serverTimestamp(),
            'action': action,
          }
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    } else {
      // DISLIKE — commit the swipe first, then clean up received_likes.
      await batch.commit();

      // Clean up received_likes in BOTH directions just to be safe.
      // 1. If toUserId liked us, remove them from our Likes You page.
      try {
        await _db
            .collection('received_likes')
            .doc(fromUserId)
            .update({toUserId: FieldValue.delete()});
      } catch (_) {}

      // 2. If we somehow previously liked toUserId, remove ourselves from their Likes You page.
      try {
        await _db
            .collection('received_likes')
            .doc(toUserId)
            .update({fromUserId: FieldValue.delete()});
      } catch (_) {}
    }
  }

  Future<List<AppUser>> getReceivedLikes(String userId) async {
    final doc = await _db.collection('received_likes').doc(userId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    // Exclude the user's own UID in case of a self-like (stale test data)
    final likerIds = data.keys.where((id) => id != userId).toList();
    if (likerIds.isEmpty) return [];
    final futures = likerIds.map((id) => getUser(id));
    final users = await Future.wait(futures);
    return users.whereType<AppUser>().toList();
  }

  /// Real-time stream of users who have liked [userId].
  /// Emits a fresh list every time the received_likes document changes
  /// (new like, dislike cleanup, or match removal).
  Stream<List<AppUser>> receivedLikesStream(String userId) {
    return _db
        .collection('received_likes')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return <AppUser>[];
      final data = doc.data() as Map<String, dynamic>;
      final likerIds = data.keys.where((id) => id != userId).toList();
      if (likerIds.isEmpty) return <AppUser>[];
      final users = await Future.wait(likerIds.map((id) => getUser(id)));
      return users.whereType<AppUser>().toList();
    });
  }

  /// Real-time stream of users who [userId] has liked.
  Stream<List<AppUser>> sentLikesStream(String userId) {
    return _db
        .collection(AppConstants.likesCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return <AppUser>[];
      final data = doc.data() as Map<String, dynamic>;
      final likedIds = data.entries
          .where((e) => e.value == 'like' || e.value == 'superLike')
          .map((e) => e.key)
          .where((id) => id != userId)
          .toList();
      if (likedIds.isEmpty) return <AppUser>[];
      final users = await Future.wait(likedIds.map((id) => getUser(id)));
      return users.whereType<AppUser>().toList();
    });
  }

  /// Real-time stream of UIDs that SUPER LIKED [userId].
  Stream<Set<String>> receivedSuperLikesStream(String userId) {
    return _db
        .collection('received_likes')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <String>{};
      final data = doc.data() as Map<String, dynamic>;
      final superLikerIds = <String>{};
      for (final entry in data.entries) {
        if (entry.key == userId) continue;
        final val = entry.value;
        if (val is Map<String, dynamic> && val['action'] == 'superLike') {
          superLikerIds.add(entry.key);
        }
      }
      return superLikerIds;
    });
  }

  Future<void> upgradeToPremium(String userId) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'isPremium': true});
  }

  Future<bool> checkMutualLike({
    required String user1Id,
    required String user2Id,
  }) async {
    final doc = await _db
        .collection(AppConstants.likesCollection)
        .doc(user2Id)
        .get();

    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    final action = data[user1Id];
    return action == 'like' || action == 'superLike';
  }

  // ── MATCHES ───────────────────────────────────────────────────────────────

  Future<String> createMatch({
    required String user1Id,
    required String user2Id,
  }) async {
    final ids = [user1Id, user2Id]..sort();
    final matchId = '${ids[0]}_${ids[1]}';

    // ── Step 1: Create the match document ──────────────────────────
    // Done separately (not in a batch with received_likes cleanup)
    // because batch.update() throws NOT_FOUND if the received_likes
    // doc doesn't exist, which would roll back the entire batch
    // and silently prevent the match from being created.
    await _db.collection(AppConstants.matchesCollection).doc(matchId).set({
      'user1Id': ids[0],
      'user2Id': ids[1],
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
      'hasUnread': false,
    });

    // ── Step 2: Clean up received_likes (best-effort) ───────────────
    // remove user2 from user1's received_likes
    try {
      await _db
          .collection('received_likes')
          .doc(user1Id)
          .update({user2Id: FieldValue.delete()});
    } catch (_) {/* doc didn't exist – nothing to clean up */}

    // remove user1 from user2's received_likes
    try {
      await _db
          .collection('received_likes')
          .doc(user2Id)
          .update({user1Id: FieldValue.delete()});
    } catch (_) {/* doc didn't exist – nothing to clean up */}

    return matchId;
  }

  Stream<List<Match>> matchesStream(String userId) {
    // Use two separate single-field queries instead of Filter.or() + orderBy
    // (which would require a composite index). Merge client-side.
    final controller = StreamController<List<Match>>.broadcast();

    List<Match> matches1 = [];
    List<Match> matches2 = [];

    void emit() {
      final combined = {...matches1, ...matches2}.toList();
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (!controller.isClosed) controller.add(combined);
    }

    final sub1 = _db
        .collection(AppConstants.matchesCollection)
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      matches1 = snap.docs.map(Match.fromFirestore).toList();
      emit();
    });

    final sub2 = _db
        .collection(AppConstants.matchesCollection)
        .where('user2Id', isEqualTo: userId)
        .snapshots()
        .listen((snap) {
      matches2 = snap.docs.map(Match.fromFirestore).toList();
      emit();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  // ── MESSAGES ──────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String matchId,
    required Message message,
  }) async {
    final batch = _db.batch();

    // Add message to subcollection
    final msgRef = _db
        .collection(AppConstants.matchesCollection)
        .doc(matchId)
        .collection(AppConstants.messagesSubcollection)
        .doc();

    batch.set(msgRef, message.toFirestore());

    // Update match with last message info
    final matchRef =
        _db.collection(AppConstants.matchesCollection).doc(matchId);
    batch.update(matchRef, {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'hasUnread': true,
    });

    await batch.commit();
  }

  Stream<List<Message>> messagesStream(String matchId) {
    return _db
        .collection(AppConstants.matchesCollection)
        .doc(matchId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Message.fromFirestore).toList());
  }

  Future<void> markMessagesRead(String matchId) async {
    await _db
        .collection(AppConstants.matchesCollection)
        .doc(matchId)
        .update({'hasUnread': false});
  }
}
