import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/image_moderation_service.dart';
import '../../services/cat_detection_service.dart';
import '../../models/app_user.dart';
import '../../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _textCtrl = TextEditingController();

  String? _chatId;
  String _otherName = 'Chat';
  String? _otherUid;

  String? _myUid;
  String _myName = 'Someone';
  final _notifs = NotificationService();
  final _storage = StorageService();
  final _moderation = ImageModerationService();
  final _catDetection = CatDetectionService();
  final _imagePicker = ImagePicker();
  bool _sendingPhoto = false;

  @override
  void initState() {
    super.initState();
    _myUid = AuthService().currentUser?.uid;
    _loadMyName();
  }

  Future<void> _loadMyName() async {
    final uid = _myUid;
    if (uid == null) return;
    try {
      final meDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!meDoc.exists) return;
      final me = AppUser.fromDoc(meDoc);
      if (!mounted) return;
      setState(() => _myName = me.name.trim().isEmpty ? 'Someone' : me.name.trim());
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final chatId = args['chatId']?.toString();
      final otherName = args['otherName']?.toString();
      final otherUid = args['otherUid']?.toString();

      setState(() {
        _chatId = chatId;
        _otherName = (otherName != null && otherName.isNotEmpty) ? otherName : 'Chat';
        _otherUid = (otherUid != null && otherUid.isNotEmpty) ? otherUid : null;
      });
    }
  }

  Future<void> _deleteMessage(String messageId, String? imagePath) async {
    final chatId = _chatId;
    if (chatId == null || chatId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        await _storage.deleteByPath(imagePath);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('PERMISSION_DENIED') || e.toString().contains('permission-denied')
            ? 'Delete not allowed. Check Firestore rules (allow delete where senderId == auth.uid).'
            : 'Could not delete: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _send() async {
    final chatId = _chatId;
    final myUid = _myUid;
    final otherUid = _otherUid;
    final text = _textCtrl.text.trim();

    if (chatId == null || chatId.isEmpty) return;
    if (myUid == null) return;
    if (text.isEmpty) return;

    _textCtrl.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': myUid,
      'ts': FieldValue.serverTimestamp(),
    });

    if (otherUid != null && otherUid.isNotEmpty) {
      await _notifs.pushMessageNotification(
        toUid: otherUid,
        fromUid: myUid,
        fromName: _myName,
        chatId: chatId,
        text: text,
      );
    }
  }

  Future<void> _sendPhoto() async {
    final chatId = _chatId;
    final myUid = _myUid;
    final otherUid = _otherUid;

    if (chatId == null || chatId.isEmpty || myUid == null) return;
    if (_sendingPhoto) return;

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send photo'),
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
    if (source == null || !mounted) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty || !mounted) return;

    setState(() => _sendingPhoto = true);

    try {
      final result = await _moderation.getModerationResult(bytes);
      if (!mounted) return;
      if (!result.allowed) {
        setState(() => _sendingPhoto = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "This photo wasn't sent. It doesn't meet our community guidelines.",
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      bool imageFlaggedSensitive = result.containsCat;
      if (!imageFlaggedSensitive) {
        final localCat = await _catDetection.containsCatFromBytes(bytes);
        if (!mounted) return;
        imageFlaggedSensitive = localCat;
      } else if (!mounted) return;

      final uploaded = await _storage.uploadChatPhoto(
        chatId: chatId,
        senderId: myUid,
        bytes: Uint8List.fromList(bytes),
      );
      if (!mounted) return;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': '',
        'imageUrl': uploaded.url,
        'imagePath': uploaded.path,
        'imageFlaggedSensitive': imageFlaggedSensitive,
        'senderId': myUid,
        'ts': FieldValue.serverTimestamp(),
      });

      if (otherUid != null && otherUid.isNotEmpty) {
        await _notifs.pushMessageNotification(
          toUid: otherUid,
          fromUid: myUid,
          fromName: _myName,
          chatId: chatId,
          text: 'Sent a photo',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingPhoto = false);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chatId = _chatId;

    if (chatId == null || chatId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_otherName), centerTitle: true),
        body: const Center(child: Text('Missing chatId')),
      );
    }

    final msgStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('ts', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(_otherName), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: msgStream,
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
                          Icon(Icons.chat_bubble_outline, color: cs.onSurfaceVariant, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'Say hi 👋',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start the convo — be nice.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final text = (data['text'] ?? '').toString();
                    final imageUrl = (data['imageUrl'] ?? '').toString();
                    final imagePath = (data['imagePath'] ?? '').toString();
                    final rawFlag = data['imageFlaggedSensitive'];
                    final imageFlaggedSensitive = rawFlag == true || rawFlag == 'true' || rawFlag == 1;
                    final senderId = (data['senderId'] ?? '').toString();
                    final mine = senderId == _myUid;

                    return MessageBubble(
                      isMe: mine,
                      isBot: false,
                      text: text,
                      imageUrl: imageUrl.isEmpty ? null : imageUrl,
                      imageFlaggedSensitive: imageFlaggedSensitive,
                      messageId: doc.id,
                      imagePath: imagePath.isEmpty ? null : imagePath,
                      onDeleteMessage: _deleteMessage,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.22 : 0.07),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _sendingPhoto ? null : _sendPhoto,
                      icon: _sendingPhoto
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_rounded),
                      tooltip: 'Send photo',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                          border: InputBorder.none,
                          filled: false,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: _send,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Icon(Icons.send_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
