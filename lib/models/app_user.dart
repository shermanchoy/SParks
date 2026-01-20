import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String course;

  final String school;
  final String intent;
  final String bio;
  final List<String> interests;

  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.course,
    required this.school,
    required this.intent,
    required this.bio,
    required this.interests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    final rawInterests = d['interests'];
    final interests = (rawInterests is List)
        ? rawInterests.map((e) => e.toString()).toList()
        : <String>[];

    DateTime parseTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return AppUser(
      uid: doc.id,
      name: (d['name'] ?? '').toString(),
      course: (d['course'] ?? '').toString(),
      school: (d['school'] ?? '').toString(),
      intent: (d['intent'] ?? '').toString(),
      bio: (d['bio'] ?? '').toString(),
      interests: interests,
      createdAt: parseTime(d['createdAt']),
      updatedAt: parseTime(d['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'course': course,
      'school': school,
      'intent': intent,
      'bio': bio,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
