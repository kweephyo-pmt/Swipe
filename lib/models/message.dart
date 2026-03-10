import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sent, delivered, read }

class Message {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;

  Message({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    return Message.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      messageId: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
    };
  }
}
