import 'dart:ui';

import 'package:flutter/material.dart';

/// Shows an image with an optional blur overlay when [flaggedAsSensitive] is true.
/// Displays a warning that the photo may contain obscene material and an "Unblur" button.
/// On tap, the blur is removed for this widget's lifetime.
class BlurredImageWithUnblur extends StatefulWidget {
  const BlurredImageWithUnblur({
    super.key,
    required this.child,
    required this.flaggedAsSensitive,
    this.width,
    this.height,
    this.borderRadius,
  });

  final Widget child;
  final bool flaggedAsSensitive;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<BlurredImageWithUnblur> createState() => _BlurredImageWithUnblurState();
}

class _BlurredImageWithUnblurState extends State<BlurredImageWithUnblur> {
  bool _revealed = false;

  bool get _showBlur => widget.flaggedAsSensitive && !_revealed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.child,
    );
    final clipped = widget.borderRadius != null
        ? ClipRRect(borderRadius: widget.borderRadius!, child: size)
        : size;

    if (!widget.flaggedAsSensitive) {
      return clipped;
    }

    if (!_showBlur) {
      return clipped;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          clipped,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This photo may contain obscene material.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => setState(() => _revealed = true),
                          icon: const Icon(Icons.visibility, size: 20),
                          label: const Text('Unblur'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
