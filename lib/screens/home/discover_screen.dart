import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/match_service.dart';
import '../../services/safety_service.dart';
import '../../utils/school_list.dart';
import '../../widgets/user_card.dart';
import '../../widgets/match_dialog.dart';
import '../../utils/home_tab.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _db = FirebaseFirestore.instance;
  final _matchService = MatchService();

  String? _schoolFilter;
  String? _intentFilter;

  bool _liking = false;
  String? _status;

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q = _db.collection('users');

    if (_schoolFilter != null && _schoolFilter!.isNotEmpty) {
      q = q.where('school', isEqualTo: _schoolFilter);
    }
    if (_intentFilter != null && _intentFilter!.isNotEmpty) {
      q = q.where('intent', isEqualTo: _intentFilter);
    }

    return q.limit(50);
  }

  Future<void> _like(AppUser other) async {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return;

    setState(() {
      _status = null;
      _liking = true;
    });

    try {
      final matched = await _matchService.likeUser(
        currentUid: currentUid,
        otherUid: other.uid,
      );

      if (!mounted) return;

      setState(() {
        _status = matched ? "It's a match with ${other.name}!" : "Liked ${other.name}";
      });

      if (matched) {
        await showMatchDialog(
          context,
          otherName: other.name,
          onSayHi: () {
            HomeTab.goMatches();
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final uid = user.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, meSnap) {
        if (meSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        AppUser? meUser;
        if (meSnap.hasData && meSnap.data!.exists) {
          meUser = AppUser.fromDoc(meSnap.data!);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _schoolFilter,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All schools')),
                      ...SchoolList.schools.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _schoolFilter = v),
                    decoration: const InputDecoration(labelText: 'School filter'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _intentFilter,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All intents')),
                      DropdownMenuItem(value: 'dating', child: Text('Dating')),
                      DropdownMenuItem(value: 'friends', child: Text('Friends')),
                      DropdownMenuItem(value: 'study', child: Text('Study buddy')),
                    ],
                    onChanged: (v) => setState(() => _intentFilter = v),
                    decoration: const InputDecoration(labelText: 'Intent filter'),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 10),
                    Text(_status!),
                  ],
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<Set<String>>(
                stream: SafetyService().watchBlocked(uid),
                builder: (context, blockedSnap) {
                  final blocked = blockedSnap.data ?? <String>{};

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _buildQuery().snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text('Error: ${snap.error}'));
                      }
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snap.hasData) {
                        return const Center(child: Text('No users found'));
                      }

                      final users = snap.data!.docs
                          .map((d) => AppUser.fromDoc(d))
                          .where((u) => u.uid != uid)
                          .where((u) => !blocked.contains(u.uid))
                          .toList();

                      if (users.isEmpty) {
                        return const Center(child: Text('No users found for this filter'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: users.length,
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return Opacity(
                            opacity: _liking ? 0.6 : 1,
                            child: UserCard(
                              user: u,
                              me: meUser,
                              onLike: _liking ? () {} : () => _like(u),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
