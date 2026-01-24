import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  Future<void> pushMatchNotification({
    required String toUid,
    required String otherName,
  }) async {
    final ref = _db
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .doc();

    await ref.set({
      'title': 'It’s a match!',
      'body': 'You matched with $otherName. Tap Say hi to start chatting.',
      'type': 'match',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
