import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirebaseFirestore.instance;

  final _name = TextEditingController();
  final _course = TextEditingController();
  final _bio = TextEditingController();
  final _interestInput = TextEditingController();

  String _school = '';
  String _intent = '';

  final List<String> _interests = [];

  bool _saving = false;
  bool _loadedOnce = false;

  // Store ONLY codes in Firestore and state (prevents dropdown crash)
  static const Map<String, String> _schoolMap = {
    'MAD': 'Media, Arts & Design (MAD)',
    'EEE': 'Electrical & Electronic Engineering (EEE)',
    'SOC': 'School of Computing (SoC)',
    'SB': 'Singapore Business School (SB)',
    'SHSS': 'Humanities & Social Sciences (SHSS)',
    'SCL': 'Chemical & Life Sciences (CLS)',
    'ASE': 'Architecture & the Built Environment (ABE)',
    'MAE': 'Mechanical & Aeronautical Engineering (MAE)',
  };

  static const Map<String, String> _intentMap = {
    'dating': 'Dating',
    'friends': 'Friends',
    'study': 'Study buddy',
  };

  @override
  void dispose() {
    _name.dispose();
    _course.dispose();
    _bio.dispose();
    _interestInput.dispose();
    super.dispose();
  }

  String _normalizeSchoolToCode(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';

    // If already a code and valid
    if (_schoolMap.containsKey(v)) return v;

    // If saved as full label previously, convert back to code
    final entry = _schoolMap.entries.firstWhere(
      (e) => e.value == v,
      orElse: () => const MapEntry('', ''),
    );
    return entry.key;
  }

  String _normalizeIntentToCode(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';

    if (_intentMap.containsKey(v)) return v;

    final entry = _intentMap.entries.firstWhere(
      (e) => e.value == v,
      orElse: () => const MapEntry('', ''),
    );
    return entry.key;
  }

  void _loadUser(AppUser u) {
    _name.text = u.name;
    _course.text = u.course;
    _bio.text = u.bio;

    _school = _normalizeSchoolToCode(u.school);
    _intent = _normalizeIntentToCode(u.intent);

    _interests
      ..clear()
      ..addAll(u.interests);

    _loadedOnce = true;
  }

  void _addInterest() {
    final v = _interestInput.text.trim();
    if (v.isEmpty) return;

    final exists = _interests.any(
      (x) => x.toLowerCase().trim() == v.toLowerCase().trim(),
    );
    if (exists) return;

    setState(() {
      _interests.add(v);
      _interestInput.clear();
    });
  }

  void _removeInterest(String v) {
    setState(() {
      _interests.removeWhere((x) => x == v);
    });
  }

  Future<void> _saveProfile({
    required String uid,
    required AppUser? current,
  }) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final now = DateTime.now();

      // Save ONLY code values for school + intent
      final updated = AppUser(
        uid: uid,
        name: name,
        course: _course.text.trim(),
        school: _school.trim(),
        intent: _intent.trim(),
        bio: _bio.text.trim(),
        interests: List<String>.from(_interests),
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
      );

      await _db.collection('users').doc(uid).set(
            updated.toMap(),
            SetOptions(merge: true),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await AuthService().signOut();
    if (!mounted) return;

    // Go back to auth gate route
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        AppUser? current;
        if (snap.hasData && snap.data!.exists) {
          current = AppUser.fromDoc(snap.data!);
          if (!_loadedOnce) {
            _loadUser(current);
          }
        }

        // Defensive: if _school value is not one of the dropdown items, reset
        if (_school.isNotEmpty && !_schoolMap.containsKey(_school)) {
          _school = '';
        }
        if (_intent.isNotEmpty && !_intentMap.containsKey(_intent)) {
          _intent = '';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                tooltip: 'Log out',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Basics',
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _course,
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          hintText: 'e.g. Diploma in Computer Engineering',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bio,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          prefixIcon: Icon(Icons.edit_note),
                          hintText: 'Keep it short and friendly',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'School and intent',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _school.isEmpty ? null : _school,
                        decoration: const InputDecoration(
                          labelText: 'School',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: _schoolMap.entries
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _school = v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _intent.isEmpty ? null : _intent,
                        decoration: const InputDecoration(
                          labelText: 'Intent',
                          prefixIcon: Icon(Icons.favorite_border),
                        ),
                        items: _intentMap.entries
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _intent = v ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Interests',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _interestInput,
                              decoration: const InputDecoration(
                                labelText: 'Add interest',
                                hintText: 'e.g. badminton, cafe hopping',
                                prefixIcon: Icon(Icons.local_offer_outlined),
                              ),
                              onSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addInterest,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_interests.isEmpty)
                        const Text(
                          'Add a few interests so your card can show chips.',
                          style: TextStyle(color: Colors.black54),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interests.map((t) {
                            return Chip(
                              label: Text(t),
                              onDeleted: () => _removeInterest(t),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save profile'),
                  onPressed:
                      _saving ? null : () => _saveProfile(uid: uid, current: current),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 16),
                if (current != null)
                  Text(
                    'Last updated: ${current.updatedAt}',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
