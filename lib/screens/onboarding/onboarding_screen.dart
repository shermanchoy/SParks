import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';
import '../../utils/validators.dart';
import '../../utils/school_list.dart';
import '../../widgets/primary_button.dart';
import '../../routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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

  @override
  void dispose() {
    _name.dispose();
    _course.dispose();
    _bio.dispose();
    _interestInput.dispose();
    super.dispose();
  }

  void _addInterest() {
    final v = _interestInput.text.trim();
    if (v.isEmpty) return;
    if (_interests.length >= 8) return;
    if (_interests.contains(v)) return;
    setState(() {
      _interests.add(v);
      _interestInput.clear();
    });
  }

  void _removeInterest(String v) {
    setState(() => _interests.remove(v));
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _school == null) {
      setState(() {
        _loading = false;
        if (_school == null) _error = 'Please select a school';
      });
      return;
    }

    final uid = AuthService().currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'Not logged in';
      });
      return;
    }

    final now = DateTime.now();
    final user = AppUser(
      uid: uid,
      name: _name.text.trim(),
      school: _school!,
      course: _course.text.trim(),
      bio: _bio.text.trim(),
      interests: _interests,
      intent: _intent,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await FirestoreService().createOrUpdateUser(user);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService().currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Create Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as: $email'),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => Validators.requiredField(v, msg: 'Name required'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _school,
                    items: SchoolList.schools
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _school = v),
                    decoration: const InputDecoration(labelText: 'School'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _course,
                    decoration: const InputDecoration(labelText: 'Course / Diploma'),
                    validator: (v) => Validators.requiredField(v, msg: 'Course required'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _bio,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Short intro about you',
                    ),
                    validator: (v) => Validators.requiredField(v, msg: 'Bio required'),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _intent,
                    items: const [
                      DropdownMenuItem(value: 'dating', child: Text('Dating')),
                      DropdownMenuItem(value: 'friends', child: Text('Friends')),
                      DropdownMenuItem(value: 'study', child: Text('Study buddy')),
                    ],
                    onChanged: (v) => setState(() => _intent = v ?? 'dating'),
                    decoration: const InputDecoration(labelText: 'Intent'),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Interests (max 8)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interestInput,
                          decoration: const InputDecoration(
                            labelText: 'Add interest',
                            hintText: 'e.g. badminton, cafe hopping',
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
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 8),

                  PrimaryButton(
                    text: 'Save Profile',
                    onPressed: _submit,
                    loading: _loading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
