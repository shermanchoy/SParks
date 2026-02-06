import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifsRef(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Future<void> push({
    required String toUid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final ref = _notifsRef(toUid).doc();
    await ref.set({
      'title': title,
      'body': body,
      'type': type,
      if (data != null) ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> pushMatchNotification({
    required String toUid,
    required String otherName,
  }) async {
    await push(
      toUid: toUid,
      title: 'It’s a match!',
      body: 'You matched with $otherName. Tap Say hi to start chatting.',
      type: 'match',
      data: {'otherName': otherName},
    );
  }

  Future<void> pushLikeNotification({
    required String toUid,
    required String fromUid,
    required String fromName,
  }) async {
    final name = fromName.trim().isEmpty ? 'Someone' : fromName.trim();
    await push(
      toUid: toUid,
      title: 'New like',
      body: '$name liked you.',
      type: 'like',
      data: {'fromUid': fromUid, 'fromName': name},
    );
  }

  Future<void> pushMessageNotification({
    required String toUid,
    required String fromUid,
    required String fromName,
    required String chatId,
    required String text,
  }) async {
    final name = fromName.trim().isEmpty ? 'Someone' : fromName.trim();
    final preview = text.trim();
    await push(
      toUid: toUid,
      title: name,
      body: preview.isEmpty ? 'Sent you a message' : preview,
      type: 'message',
      data: {
        'fromUid': fromUid,
        'fromName': name,
        'chatId': chatId,
      },
    );
  }
}
