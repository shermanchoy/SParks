import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final bool isBot;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.isBot,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isBot
        ? const Color(0xFFF1F1F1)
        : (isMe ? const Color(0xFFE53935) : const Color(0xFFF7F7F7));

    final fg = isBot ? Colors.black : (isMe ? Colors.white : Colors.black);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: TextStyle(color: fg)),
      ),
    );
  }
}
