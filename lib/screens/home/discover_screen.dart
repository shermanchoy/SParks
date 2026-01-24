import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/match_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _match = MatchService();

  bool _loading = true;
  String? _status;

  final List<AppUser> _stack = [];
  final List<AppUser> _history = [];

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      setState(() {
        _status = 'Please login again.';
        _loading = false;
      });
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: uid)
          .limit(50)
          .get();

      final list = snap.docs.map((d) => AppUser.fromDoc(d)).toList();

      if (!mounted) return;
      setState(() {
        _stack
          ..clear()
          ..addAll(list);
        _history.clear();
        _loading = false;
        _status = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _likeTop() async {
    if (_stack.isEmpty || _busy) return;

    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return;

    final other = _stack.first;

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      // get my name for storing into other user's matches doc
      final meDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      final me = meDoc.exists ? AppUser.fromDoc(meDoc) : null;

      final chatId = await _match.likeUser(
        currentUid: currentUid,
        otherUid: other.uid,
        currentName: me?.name.isNotEmpty == true ? me!.name : 'Someone',
        otherName: other.name.isNotEmpty ? other.name : 'Someone',
      );

      if (!mounted) return;

      setState(() {
        _history.add(_stack.removeAt(0));
        _busy = false;
      });

      if (chatId != null) {
        await _showMatchDialog(other, chatId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = e.toString();
      });
    }
  }

  Future<void> _passTop() async {
    if (_stack.isEmpty || _busy) return;

    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return;

    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      // optional: record pass, if your MatchService has passUser
      // await _match.passUser(currentUid: currentUid, otherUid: other.uid);

      if (!mounted) return;

      setState(() {
        _history.add(_stack.removeAt(0));
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = e.toString();
      });
    }
  }

  void _goBack() {
    if (_history.isEmpty || _busy) return;
    setState(() {
      _stack.insert(0, _history.removeLast());
    });
  }

  Future<void> _showMatchDialog(AppUser other, String chatId) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("It's a match!"),
          content: Text('You matched with ${other.name.isNotEmpty ? other.name : "Someone"}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  Routes.chat,
                  arguments: {
                    'chatId': chatId,
                    'otherUid': other.uid,
                    'otherName': other.name.isNotEmpty ? other.name : 'Someone',
                  },
                );
              },
              child: const Text('Go say hi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_status != null) return Center(child: Text(_status!));

    if (_stack.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No more users to show.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Reload')),
          ],
        ),
      );
    }

    final u = _stack.first;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name.isNotEmpty ? u.name : 'Someone',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    if (u.school.isNotEmpty) Text(u.school),
                    const SizedBox(height: 6),
                    if (u.course.isNotEmpty) Text(u.course),
                    const SizedBox(height: 12),
                    if (u.intent.isNotEmpty) Text(u.intent),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: u.interests.map((t) => Chip(label: Text(t))).toList(),
                    ),
                    const Spacer(),
                    if (_busy) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: _history.isEmpty ? null : _goBack,
                icon: const Icon(Icons.undo),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _passTop,
                  icon: const Icon(Icons.close),
                  label: const Text('Pass'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _likeTop,
                  icon: const Icon(Icons.favorite),
                  label: const Text('Like'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
