import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

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
}
