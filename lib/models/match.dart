import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';
import '../../utils/school_list.dart';
import '../../utils/validators.dart';
import '../../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirestoreService();

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _course = TextEditingController();
  final _bio = TextEditingController();
  final _interestInput = TextEditingController();

  String? _school;
  String _intent = 'dating';
  final List<String> _interests = [];

  bool _loading = false;
  String? _error;
  bool _loadedOnce = false;

  @override
  void dispose() {
    _name.dispose();
    _course.dispose();
    _bio.dispose();
    _interestInput.dispose();
    super.dispose();
  }

  void _loadUser(AppUser u) {
    _name.text = u.name;
    _course.text = u.course;
    _bio.text = u.bio;
    final allowed = {'MAD','EEE','SOC','SB','SHSS','SCL','ASE','MAE'};
_school = allowed.contains(u.school) ? u.school : '';
    _intent = u.intent;
    _interests
      ..clear()
      ..addAll(u.interests);
    _loadedOnce = true;
  }

  void _addInterest() {
    final v = _interestInput.text.trim();
    if (v.isEmpty) return;
    if (_interests.contains(v)) return;
    if (_interests.length >= 8) return;

    setState(() {
      _interests.add(v);
      _interestInput.clear();
    });
  }

  void _removeInterest(String v) {
    setState(() => _interests.remove(v));
  }

  Future<void> _save(String uid, AppUser current) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _school == null) {
      setState(() {
        _loading = false;
        _error = 'Please complete all fields';
      });
      return;
    }

    final updated = AppUser(
      uid: uid,
      name: _name.text.trim(),
      school: _school!,
      course: _course.text.trim(),
      bio: _bio.text.trim(),
      interests: List<String>.from(_interests),
      intent: _intent,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _db.createOrUpdateUser(updated);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: _db.watchUser(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Profile not found')),
          );
        }

        if (!_loadedOnce) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _loadUser(user));
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        Validators.requiredField(v, msg: 'Name required'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _school,
                    decoration: const InputDecoration(labelText: 'School'),
                    items: SchoolList.schools
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _school = v),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _course,
                    decoration:
                        const InputDecoration(labelText: 'Course / Diploma'),
                    validator: (v) =>
                        Validators.requiredField(v, msg: 'Course required'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _bio,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    validator: (v) =>
                        Validators.requiredField(v, msg: 'Bio required'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _intent,
                    decoration: const InputDecoration(labelText: 'Intent'),
                    items: const [
                      DropdownMenuItem(
                          value: 'dating', child: Text('Dating')),
                      DropdownMenuItem(
                          value: 'friends', child: Text('Friends')),
                      DropdownMenuItem(
                          value: 'study', child: Text('Study buddy')),
                    ],
                    onChanged: (v) => setState(() => _intent = v ?? 'dating'),
                  ),
                  const SizedBox(height: 16),

                  const Text('Interests (max 8)'),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interestInput,
                          decoration: const InputDecoration(
                            labelText: 'Add interest',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addInterest,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _interests
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            onDeleted: () => _removeInterest(t),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Save Changes',
                    onPressed: () => _save(uid, user),
                    loading: _loading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
