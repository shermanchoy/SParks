import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('chatRooms');

  String chatIdFor(String uidA, String uidB) {
    final a = uidA.trim();
    final b = uidB.trim();
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

  DocumentReference<Map<String, dynamic>> roomRef(String chatId) => _rooms.doc(chatId);

  CollectionReference<Map<String, dynamic>> messagesRef(String chatId) =>
      roomRef(chatId).collection('messages');

  Future<String> ensureChatRoom({
    required String uidA,
    required String uidB,
    String? nameA,
    String? nameB,
  }) async {
    final chatId = chatIdFor(uidA, uidB);
    final ref = roomRef(chatId);

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [uidA, uidB],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        // optional names (useful for UI)
        'nameA': nameA ?? '',
        'nameB': nameB ?? '',
      });
    }

    return chatId;
  }

  Stream<List<Map<String, dynamic>>> watchMyChatRooms(String myUid) {
    return _rooms
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'chatId': d.id,
          ...data,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    return messagesRef(chatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final msgRef = messagesRef(chatId).doc();
    await msgRef.set({
      'senderId': senderId,
      'text': t,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await roomRef(chatId).set({
      'lastMessage': t,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }
}
