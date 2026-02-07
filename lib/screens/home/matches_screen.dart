import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/blurred_image_with_unblur.dart';
import '../../widgets/network_circle_avatar.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 40, color: cs.onSurfaceVariant),
                  const SizedBox(height: 10),
                  Text('No matches yet.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'When you match with someone, they’ll show up here.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
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
            final photoUrl = (data['photoUrl'] ?? '').toString();
            final photoPath = (data['photoPath'] ?? '').toString();
            final photoFlaggedSensitive = data['photoFlaggedSensitive'] == true;
            final label = otherName.trim().isEmpty ? 'Someone' : otherName.trim();
            final initial = label.characters.isEmpty ? '?' : label.characters.first.toUpperCase();
            final canChat = chatId.isNotEmpty;
            final hasPhoto = photoUrl.isNotEmpty || photoPath.isNotEmpty;

            void openChat() {
              if (!canChat) return;
              Navigator.pushNamed(
                context,
                Routes.chatRoute(
                  chatId: chatId,
                  otherUid: otherUid,
                  otherName: label,
                ),
                arguments: {
                  'chatId': chatId,
                  'otherUid': otherUid,
                  'otherName': label,
                },
              );
            }

            final avatar = hasPhoto
                ? BlurredImageWithUnblur(
                    flaggedAsSensitive: photoFlaggedSensitive,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(22),
                    child: NetworkCircleAvatar(
                      radius: 22,
                      url: photoUrl,
                      storagePath: photoPath,
                      backgroundColor: cs.surfaceVariant,
                      placeholder: Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          const Color(0xFFFF6B6B),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(theme.brightness == Brightness.dark ? 0.28 : 0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 240 + (i.clamp(0, 8) * 45)),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) {
                final slide = (1 - v) * 10;
                return Opacity(
                  opacity: v,
                  child: Transform.translate(offset: Offset(0, slide), child: child),
                );
              },
              child: Card(
                child: ListTile(
                  onTap: openChat,
                  leading: avatar,
                  title: Text(label),
                  subtitle: Text(canChat ? 'Tap to chat' : 'Setting up chat…'),
                  trailing: FilledButton(
                    onPressed: canChat ? openChat : null,
                    child: const Text('Say hi'),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
