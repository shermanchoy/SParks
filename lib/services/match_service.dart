import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

class MatchService {
  final _db = FirebaseFirestore.instance;
  final _notifs = NotificationService();

  /// returns chatId if matched, otherwise null
  Future<String?> likeUser({
    required String currentUid,
    required String otherUid,
    required String currentName,
    required String otherName,
  }) async {
    final otherLikeRef =
        _db.collection('likes').doc(otherUid).collection('liked').doc(currentUid);

    final myLikeRef =
        _db.collection('likes').doc(currentUid).collection('liked').doc(otherUid);

    // record my like
    await myLikeRef.set({
      'uid': otherUid,
      'ts': FieldValue.serverTimestamp(),
    });

    // notify the other user they got a like
    await _notifs.pushLikeNotification(
      toUid: otherUid,
      fromUid: currentUid,
      fromName: currentName,
    );

    final otherLikeSnap = await otherLikeRef.get();

    // NOT a match yet
    if (!otherLikeSnap.exists) return null;

    // MATCH 🔥
    final chatRef = await _db.collection('chats').add({
      'users': [currentUid, otherUid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final chatId = chatRef.id;

    // save match for both users
    await _db
        .collection('matches')
        .doc(currentUid)
        .collection('list')
        .doc(otherUid)
        .set({
      'uid': otherUid,
      'chatId': chatId,
      'name': otherName,
    });

    await _db
        .collection('matches')
        .doc(otherUid)
        .collection('list')
        .doc(currentUid)
        .set({
      'uid': currentUid,
      'chatId': chatId,
      'name': currentName,
    });

    // notify both users of the match
    await _notifs.pushMatchNotification(toUid: currentUid, otherName: otherName);
    await _notifs.pushMatchNotification(toUid: otherUid, otherName: currentName);

    return chatId;
  }

  Stream<QuerySnapshot> watchMatchesRaw(String uid) {
    return _db.collection('matches').doc(uid).collection('list').snapshots();
  }
}
