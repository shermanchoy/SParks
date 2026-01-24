import 'package:flutter/material.dart';

class SparksTitle extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final Color? arksColor;

  const SparksTitle({
    super.key,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w700,
    this.arksColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.5,
        ),
        children: [
          const TextSpan(
            text: 'sp',
            style: TextStyle(color: Color.fromARGB(255, 183, 0, 255)), // red
          ),
          TextSpan(
            text: 'arks',
            style: TextStyle(
              color: arksColor ?? theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
