import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  final _db = FirebaseFirestore.instance;

  String matchIdFor(String a, String b) {
    final s = [a, b]..sort();
    return '${s[0]}_${s[1]}';
  }

  DocumentReference<Map<String, dynamic>> _outgoingLikeRef(
    String fromUid,
    String toUid,
  ) {
    return _db
        .collection('likes')
        .doc(fromUid)
        .collection('outgoing')
        .doc(toUid);
  }

  DocumentReference<Map<String, dynamic>> _incomingLikeRef(
    String toUid,
    String fromUid,
  ) {
    return _db
        .collection('likes')
        .doc(toUid)
        .collection('incoming')
        .doc(fromUid);
  }

  Future<bool> likeUser({
    required String currentUid,
    required String otherUid,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _outgoingLikeRef(currentUid, otherUid).set({'createdAt': now});
    await _incomingLikeRef(otherUid, currentUid).set({'createdAt': now});

    final reciprocal = await _outgoingLikeRef(otherUid, currentUid).get();
    if (!reciprocal.exists) return false;

    final matchId = matchIdFor(currentUid, otherUid);

    await _db.collection('matches').doc(matchId).set({
      'users': [currentUid, otherUid],
      'createdAt': now,
      'lastMessage': null,
      'lastMessageAt': null,
    }, SetOptions(merge: true));

    return true;
  }
}
