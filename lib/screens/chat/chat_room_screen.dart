import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/bot_service.dart';
import '../../services/safety_service.dart';
import '../../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final String matchId;
  final String otherUid;
  final String otherName;

  const ChatRoomScreen({
    super.key,
    required this.matchId,
    required this.otherUid,
    required this.otherName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _chat = ChatService();
  final _controller = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendUserMessage() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _busy = true);
    try {
      await _chat.sendMessage(
        matchId: widget.matchId,
        senderId: uid,
        text: text,
        type: 'user',
      );
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _botSuggest() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    String prompt = _controller.text.trim();

    // If input is empty, use last message from chat
    if (prompt.isEmpty) {
      try {
        final last = await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (last.docs.isNotEmpty) {
          final data = last.docs.first.data();
          prompt = (data['text'] ?? '').toString();
        }
      } catch (_) {}
    }

    final reply = BotService.reply(prompt);

    setState(() => _busy = true);
    try {
      await _chat.sendMessage(
        matchId: widget.matchId,
        senderId: 'bot',
        text: reply,
        type: 'bot',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bot failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _blockUser() async {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Block user?'),
        content: const Text('You will no longer see this user in Discover.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await SafetyService().blockUser(uid: myUid, otherUid: widget.otherUid);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked')),
    );
  }

  Future<void> _reportUser() async {
    final myUid = AuthService().currentUser?.uid;
    if (myUid == null) return;

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report user'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    final r = (reason ?? '').trim();
    if (r.isEmpty) return;

    await SafetyService().reportUser(
      reporterUid: myUid,
      reportedUid: widget.otherUid,
      reason: r,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: 'Assistant',
            onPressed: _busy ? null : _botSuggest,
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'report') await _reportUser();
              if (v == 'block') await _blockUser();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Report')),
              PopupMenuItem(value: 'block', child: Text('Block')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chat.streamMessagesRaw(widget.matchId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hi'));
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final senderId = (d['senderId'] ?? '') as String;
                    final text = (d['text'] ?? '') as String;
                    final type = (d['type'] ?? 'user') as String;

                    final isBot = type == 'bot' || senderId == 'bot';
                    final isMe = senderId == myUid;

                    return MessageBubble(
                      isMe: isMe,
                      isBot: isBot,
                      text: text,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _busy ? null : _sendUserMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : _sendUserMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
