import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _users.doc(uid);

  Future<bool> userProfileExists(String uid) async {
    final doc = await userRef(uid).get();
    return doc.exists;
  }

  Stream<AppUser?> watchUser(String uid) {
    return userRef(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await userRef(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> createOrUpdateUser(AppUser user) async {
    await userRef(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // ✅ ADD THIS: used by DiscoverScreen
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> usersQuery({
    required int limit,
    required String excludeUid,
  }) async {
    final snap = await _users.orderBy('updatedAt', descending: true).limit(limit).get();

    final docs = snap.docs.where((d) => d.id != excludeUid).toList();
    return docs;
  }
}
