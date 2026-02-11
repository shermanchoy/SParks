import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/school_list.dart';
import '../../services/storage_service.dart';
import '../../services/cat_detection_service.dart';
import '../../widgets/network_circle_avatar.dart';
import '../../widgets/blurred_image_with_unblur.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirestoreService();
  final _storage = StorageService();
  final _catDetection = CatDetectionService();

  final _name = TextEditingController();
  final _course = TextEditingController();
  final _bio = TextEditingController();

  static const _intents = <String>['Dating', 'Friends', 'Networking'];

  String _school = SchoolList.schools.first;
  String _intent = _intents.first;

  final List<String> _interests = [];
  final _interestCtrl = TextEditingController();

  bool _saving = false;
  bool _photoBusy = false;
  double? _photoProgress;
  String? _status;

  AppUser? _current;
  String _photoUrl = '';
  String _photoPath = '';
  bool _photoFlaggedSensitive = false;
  Uint8List? _localPhotoBytes;

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
      _photoUrl = u.photoUrl;
      _photoPath = u.photoPath;
      _photoFlaggedSensitive = u.photoFlaggedSensitive;

      _school = SchoolList.schools.contains(u.school) ? u.school : SchoolList.schools.first;
      _intent = _intents.contains(u.intent) ? u.intent : _intents.first;

      _interests
        ..clear()
        ..addAll(u.interests);
    }

    setState(() {});
  }

  Future<void> _pickAndUploadPhoto() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    if (_photoBusy) return;

    setState(() {
      _photoBusy = true;
      _photoProgress = null;
      _status = null;
    });

    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Profile photo'),
          content: const Text(
            'Take a new photo with the camera, or choose from your gallery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take photo'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      );
      if (source == null || !mounted) {
        setState(() {
          _photoBusy = false;
          _photoProgress = null;
        });
        return;
      }

      final file = await picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1024,
      );
      if (file == null) {
        if (mounted) {
          setState(() {
            _photoBusy = false;
            _photoProgress = null;
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _localPhotoBytes = bytes;
        });
      }

      final containsCat = await _catDetection.containsCatFromBytes(bytes);
      assert(() {
        debugPrint('[ProfileScreen] containsCat=$containsCat, will set _photoFlaggedSensitive');
        return true;
      }());
      if (!mounted) return;

      final oldPath = _photoPath;
      final uploaded = await _storage.uploadProfilePhoto(
        uid: uid,
        bytes: bytes,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _photoProgress = p);
        },
      );

      if (mounted) {
        await precacheImage(
          NetworkImage(uploaded.photoUrl),
          context,
        ).timeout(const Duration(seconds: 15));
      }

      if (mounted) {
        setState(() {
          _photoUrl = uploaded.photoUrl;
          _photoPath = uploaded.photoPath;
          _photoFlaggedSensitive = containsCat;
          _photoBusy = false;
          _photoProgress = null;
        });
      }

      await _db.userRef(uid).set({
        'photoUrl': uploaded.photoUrl,
        'photoPath': uploaded.photoPath,
        'photoFlaggedSensitive': containsCat,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 20));

      if (oldPath.trim().isNotEmpty && oldPath.trim() != uploaded.photoPath) {
        await _storage.deleteByPath(oldPath);
      }

      if (!mounted) return;
      setState(() {
        _status = 'Photo updated!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _photoBusy = false;
        _photoProgress = null;
        _status = 'Photo upload failed: $e';
      });
    }
  }

  Future<void> _removePhoto() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    if (_photoBusy) return;

    setState(() {
      _photoBusy = true;
      _status = null;
    });

    try {
      final oldPath = _photoPath;
      if (oldPath.trim().isNotEmpty) {
        await _storage.deleteByPath(oldPath);
      }

      await _db.userRef(uid).set({
        'photoUrl': '',
        'photoPath': '',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _photoUrl = '';
        _photoPath = '';
        _photoFlaggedSensitive = false;
        _localPhotoBytes = null;
        _photoBusy = false;
        _status = 'Photo removed';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _photoBusy = false;
        _status = e.toString();
      });
    }
  }

  Future<void> _runStorageProbe() async {
    if (_photoBusy) return;
    final uid = AuthService().currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() => _status = 'Not logged in (no uid). Sign in, then try again.');
      return;
    }
    setState(() {
      _photoBusy = true;
      _photoProgress = 0;
      _status = null;
    });
    try {
      final msg = await _storage.probe(uid: uid);
      if (!mounted) return;
      setState(() {
        _status = msg;
        _photoBusy = false;
        _photoProgress = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Probe failed: $e';
        _photoBusy = false;
        _photoProgress = null;
      });
    }
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
        photoUrl: _photoUrl,
        photoPath: _photoPath,
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
    final successStatus = _status == 'Saved!' || _status == 'Photo updated!' || _status == 'Photo removed';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_status != null) ...[
          Text(
            _status!,
            style: TextStyle(color: successStatus ? Colors.green : Colors.red),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: BlurredImageWithUnblur(
                    flaggedAsSensitive: _photoFlaggedSensitive,
                    width: 96,
                    height: 96,
                    borderRadius: BorderRadius.circular(48),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        NetworkCircleAvatar(
                          radius: 48,
                          url: _photoUrl,
                          storagePath: _photoPath,
                          placeholder: const Icon(Icons.person, size: 44),
                        ),
                        if (_localPhotoBytes != null)
                          IgnorePointer(
                            child: ClipOval(
                              child: Image.memory(
                                _localPhotoBytes!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        if (_photoBusy) ...[
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.10),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              value: (_photoProgress != null && _photoProgress! > 0 && _photoProgress! < 1)
                                  ? _photoProgress
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_photoBusy && _photoProgress != null)
                  Text(
                    '${(_photoProgress! * 100).round()}%',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: _photoBusy ? null : _pickAndUploadPhoto,
                      icon: const Icon(Icons.photo_camera),
                      label: Text(_photoUrl.trim().isEmpty ? 'Add photo' : 'Change'),
                    ),
                    const SizedBox(width: 10),
                    if (_photoUrl.trim().isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _photoBusy ? null : _removePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _photoBusy ? null : _runStorageProbe,
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test Storage connection'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _school,
          isExpanded: true,
          items: SchoolList.schools
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          selectedItemBuilder: (context) => SchoolList.schools
              .map((s) => Text(s, overflow: TextOverflow.ellipsis, maxLines: 1))
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
