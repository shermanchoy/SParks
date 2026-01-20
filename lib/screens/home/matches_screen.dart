import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../chat/chat_room_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not logged in'));
    }

    final q = FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: uid);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No matches yet'));
        }

        final docs = snap.data!.docs.toList();

        // Sort locally by createdAt (no index needed)
        docs.sort((a, b) {
          final aTs = a.data()['createdAt'];
          final bTs = b.data()['createdAt'];
          final aTime = (aTs is Timestamp)
              ? aTs.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = (bTs is Timestamp)
              ? bTs.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();

            final users = List<String>.from((data['users'] ?? []) as List);
            final otherUid =
                users.firstWhere((x) => x != uid, orElse: () => 'Unknown');

            final lastMsg = (data['lastMessage'] as String?)?.trim();
            final subtitle =
                (lastMsg == null || lastMsg.isEmpty) ? 'Say hi' : lastMsg;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUid)
                  .get(),
              builder: (context, userSnap) {
                String title = 'Match';
                String school = '';

                if (userSnap.connectionState == ConnectionState.waiting) {
                  title = 'Loading...';
                } else if (userSnap.hasData && userSnap.data!.exists) {
                  final u = userSnap.data!.data()!;
                  final name = (u['name'] as String?)?.trim() ?? '';
                  title = name.isNotEmpty ? name : 'Match';
                  school = (u['school'] as String?) ?? '';
                } else {
                  title = 'Match: $otherUid';
                }

                return ListTile(
                  tileColor: const Color(0xFFF7F7F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    school.isEmpty ? subtitle : '$school\n$subtitle',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: school.isNotEmpty,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          matchId: doc.id,
                          otherUid: otherUid,
                          otherName: title,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
