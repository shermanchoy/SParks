import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessagesRaw(String matchId) {
    return FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
    required String type,
  }) async {
    final msg = text.trim();
    if (msg.isEmpty) return;

    final now = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': msg,
      'type': type,
      'createdAt': now,
    });

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .set({
      'lastMessage': msg,
      'lastMessageAt': now,
    }, SetOptions(merge: true));
  }
}
