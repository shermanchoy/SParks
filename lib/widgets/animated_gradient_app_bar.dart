import 'package:flutter/material.dart';

class SparksTitle extends StatelessWidget {
  const SparksTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // This title is primarily used on our gradient app bars.
    // Use a high-contrast color consistently.
    final arksColor = theme.colorScheme.onPrimary;

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        children: [
          const TextSpan(text: 'sp', style: TextStyle(color: Color(0xFFE53935))),
          TextSpan(text: 'arks', style: TextStyle(color: arksColor)),
        ],
      ),
    );
  }
}

class AnimatedGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final String? subtitle;
  final List<Widget>? actions;

  const AnimatedGradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9C93),
              Color(0xFFE53935),
            ],
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.90),
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }
}
