import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final bool isBot;
  /// Optional image URL for photo messages.
  final String? imageUrl;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.isBot,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.78;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final hasText = text.trim().isNotEmpty;

    final mineGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cs.primary,
        const Color(0xFFFF6B6B),
      ],
    );

    final otherBg = isBot
        ? cs.surfaceVariant.withOpacity(theme.brightness == Brightness.dark ? 0.65 : 0.55)
        : cs.surface;
    final otherBorder = cs.outlineVariant.withOpacity(0.65);

    final fg = isMe ? Colors.white : cs.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth.clamp(0, 460)),
        decoration: BoxDecoration(
          gradient: isMe ? mineGradient : null,
          color: isMe ? null : otherBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
          border: isMe ? null : Border.all(color: otherBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.22 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: 220,
                  height: 220,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 220,
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            if (hasImage && hasText) const SizedBox(height: 8),
            if (hasText)
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: fg, height: 1.25),
              ),
            if (!hasText && !hasImage)
              Text(
                ' ',
                style: theme.textTheme.bodyMedium?.copyWith(color: fg, height: 1.25),
              ),
          ],
        ),
      ),
    );
  }
}
