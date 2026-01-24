import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/auth_service.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please login again.'));
    }

    final stream = FirebaseFirestore.instance
        .collection('matches')
        .doc(uid)
        .collection('list')
        .orderBy('uid')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text(snap.error.toString()));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No matches yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final otherUid = (data['uid'] ?? '').toString();
            final otherName = (data['name'] ?? 'Someone').toString();
            final chatId = (data['chatId'] ?? '').toString();

            return Card(
              child: ListTile(
                title: Text(otherName),
                subtitle: Text(otherUid.isEmpty ? '' : 'Matched user'),
                trailing: FilledButton(
                  onPressed: chatId.isEmpty
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            Routes.chat,
                            arguments: {
                              'chatId': chatId,
                              'otherUid': otherUid,
                              'otherName': otherName,
                            },
                          );
                        },
                  child: const Text('Say hi'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
