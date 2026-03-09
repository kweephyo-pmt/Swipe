import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String matchId;
  final String user1Id;
  final String user2Id;
  final DateTime timestamp;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnread;

  Match({
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    required this.timestamp,
    this.lastMessage,
    this.lastMessageTime,
    this.hasUnread = false,
  });

  String otherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      matchId: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      hasUnread: data['hasUnread'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'timestamp': Timestamp.fromDate(timestamp),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'hasUnread': hasUnread,
    };
  }
}
