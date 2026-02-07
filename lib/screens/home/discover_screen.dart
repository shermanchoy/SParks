import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../services/match_service.dart';
import '../../widgets/match_dialog.dart';
import '../../widgets/user_card.dart';

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
        otherPhotoUrl: other.photoUrl,
        otherPhotoPath: other.photoPath,
        otherPhotoFlaggedSensitive: other.photoFlaggedSensitive,
        currentPhotoUrl: me?.photoUrl ?? '',
        currentPhotoPath: me?.photoPath ?? '',
        currentPhotoFlaggedSensitive: me?.photoFlaggedSensitive ?? false,
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
    final otherName = other.name.isNotEmpty ? other.name : 'Someone';
    await showMatchDialog(
      context,
      otherName: otherName,
      onSayHi: () {
        Navigator.pushNamed(
          context,
          Routes.chatRoute(
            chatId: chatId,
            otherUid: other.uid,
            otherName: otherName,
          ),
          arguments: {
            'chatId': chatId,
            'otherUid': other.uid,
            'otherName': otherName,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_status != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 36, color: cs.error),
              const SizedBox(height: 10),
              Text(_status!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_stack.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_outlined, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              'No more users right now.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final u = _stack.first;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(u.uid),
                        child: UserCard(user: u),
                      ),
                    ),
                  ),
                  if (_busy)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: cs.surfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RoundActionButton(
                  tooltip: 'Undo',
                  icon: Icons.undo_rounded,
                  onPressed: (_history.isEmpty || _busy) ? null : _goBack,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _passTop,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Pass'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _likeTop,
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Like'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: onPressed == null ? cs.onSurface.withOpacity(0.35) : null),
          ),
        ),
      ),
    );
  }
}
