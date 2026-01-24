import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/school_list.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirestoreService();

  final _name = TextEditingController();
  final _course = TextEditingController();
  final _bio = TextEditingController();

  static const _intents = <String>['Dating', 'Friends', 'Networking'];

  String _school = SchoolList.schools.first;
  String _intent = _intents.first;

  final List<String> _interests = [];
  final _interestCtrl = TextEditingController();

  bool _saving = false;
  String? _status;

  AppUser? _current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final u = await _db.getUser(uid);
    if (!mounted) return;

    if (u != null) {
      _current = u;
      _name.text = u.name;
      _course.text = u.course;
      _bio.text = u.bio;

      _school = SchoolList.schools.contains(u.school) ? u.school : SchoolList.schools.first;
      _intent = _intents.contains(u.intent) ? u.intent : _intents.first;

      _interests
        ..clear()
        ..addAll(u.interests);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _course.dispose();
    _bio.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  void _addInterest() {
    final v = _interestCtrl.text.trim();
    if (v.isEmpty) return;
    if (_interests.contains(v)) return;
    setState(() {
      _interests.add(v);
      _interestCtrl.clear();
    });
  }

  void _removeInterest(String v) {
    setState(() => _interests.remove(v));
  }

  Future<void> _save() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _status = null;
    });

    try {
      final now = DateTime.now();
      final existing = _current;

      final user = AppUser(
        uid: uid,
        name: _name.text.trim(),
        course: _course.text.trim(),
        school: _school,
        intent: _intent,
        bio: _bio.text.trim(),
        interests: List<String>.from(_interests),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      await _db.createOrUpdateUser(user);

      if (!mounted) return;
      setState(() {
        _current = user;
        _saving = false;
        _status = 'Saved!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _status = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_status != null) ...[
          Text(_status!, style: TextStyle(color: _status == 'Saved!' ? Colors.green : Colors.red)),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _school,
          items: SchoolList.schools
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _school = v ?? SchoolList.schools.first),
          decoration: const InputDecoration(labelText: 'School'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _course,
          decoration: const InputDecoration(labelText: 'Course'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _intent,
          items: _intents.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _intent = v ?? _intents.first),
          decoration: const InputDecoration(labelText: 'Intent'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bio,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Bio'),
  
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _interestCtrl,
                decoration: const InputDecoration(labelText: 'Add interest'),
                onSubmitted: (_) => _addInterest(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _addInterest,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interests
              .map(
                (t) => Chip(
                  label: Text(t),
                  onDeleted: () => _removeInterest(t),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const Text('Saving...') : const Text('Save Profile'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

 
}
