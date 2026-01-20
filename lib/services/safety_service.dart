import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyService {
  final _db = FirebaseFirestore.instance;

  Stream<Set<String>> watchBlocked(String uid) {
    return _db
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> blockUser({
    required String uid,
    required String otherUid,
  }) async {
    await _db
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .doc(otherUid)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser({
    required String uid,
    required String otherUid,
  }) async {
    await _db
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .doc(otherUid)
        .delete();
  }

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
  }) async {
    await _db.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
