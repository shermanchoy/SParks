import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_service.dart';

class MatchService {
  final _db = FirebaseFirestore.instance;
  final _notifs = NotificationService();

  Future<String?> likeUser({
    required String currentUid,
    required String otherUid,
    required String currentName,
    required String otherName,
    String otherPhotoUrl = '',
    String otherPhotoPath = '',
    String currentPhotoUrl = '',
    String currentPhotoPath = '',
    bool otherPhotoFlaggedSensitive = false,
    bool currentPhotoFlaggedSensitive = false,
  }) async {
    final otherLikeRef =
        _db.collection('likes').doc(otherUid).collection('liked').doc(currentUid);

    final myLikeRef =
        _db.collection('likes').doc(currentUid).collection('liked').doc(otherUid);

    await myLikeRef.set({
      'uid': otherUid,
      'ts': FieldValue.serverTimestamp(),
    });

    await _notifs.pushLikeNotification(
      toUid: otherUid,
      fromUid: currentUid,
      fromName: currentName,
    );

    final otherLikeSnap = await otherLikeRef.get();

    if (!otherLikeSnap.exists) return null;

    final chatRef = await _db.collection('chats').add({
      'users': [currentUid, otherUid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final chatId = chatRef.id;

    await _db
        .collection('matches')
        .doc(currentUid)
        .collection('list')
        .doc(otherUid)
        .set({
      'uid': otherUid,
      'chatId': chatId,
      'name': otherName,
      'photoUrl': otherPhotoUrl,
      'photoPath': otherPhotoPath,
      'photoFlaggedSensitive': otherPhotoFlaggedSensitive,
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
      'photoUrl': currentPhotoUrl,
      'photoPath': currentPhotoPath,
      'photoFlaggedSensitive': currentPhotoFlaggedSensitive,
    });

    await _notifs.pushMatchNotification(toUid: currentUid, otherName: otherName);
    await _notifs.pushMatchNotification(toUid: otherUid, otherName: currentName);

    return chatId;
  }

  Stream<QuerySnapshot> watchMatchesRaw(String uid) {
    return _db.collection('matches').doc(uid).collection('list').snapshots();
  }
}
