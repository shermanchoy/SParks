import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NetworkCircleAvatar extends StatelessWidget {
  final double radius;
  final String url;
  final String storagePath;
  final Color? backgroundColor;
  final Widget? placeholder;

  const NetworkCircleAvatar({
    super.key,
    required this.radius,
    required this.url,
    this.storagePath = '',
    this.backgroundColor,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = backgroundColor ?? cs.surfaceVariant;
    final fallback = placeholder ?? Icon(Icons.person, size: radius, color: cs.onSurfaceVariant);
    final u = url.trim();
    final p = storagePath.trim();

    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        color: bg,
        child: (u.isEmpty && p.isEmpty)
            ? Center(child: fallback)
            : (kIsWeb && p.isNotEmpty)
                ? _StorageBytesImage(radius: radius, path: p, fallback: fallback)
                : Image.network(
                    u,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stack) {
                      return Center(
                        child: Icon(Icons.broken_image_outlined, color: cs.error, size: radius * 0.9),
                      );
                    },
                    loadingBuilder: (context, child, loading) {
                      if (loading == null) return child;
                      return Center(
                        child: SizedBox(
                          width: radius * 0.65,
                          height: radius * 0.65,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _StorageBytesImage extends StatelessWidget {
  final double radius;
  final String path;
  final Widget fallback;

  const _StorageBytesImage({
    required this.radius,
    required this.path,
    required this.fallback,
  });

  Future<Uint8List?> _load() async {
    final ref = FirebaseStorage.instance.ref().child(path);
    return await ref.getData(15 * 1024 * 1024).timeout(const Duration(seconds: 25));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List?>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: radius * 0.65,
              height: radius * 0.65,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError) {
          return _StorageUrlImage(radius: radius, path: path, fallback: fallback);
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return _StorageUrlImage(radius: radius, path: path, fallback: fallback);
        }
        return Image.memory(bytes, fit: BoxFit.cover, filterQuality: FilterQuality.medium, gaplessPlayback: true);
      },
    );
  }
}

class _StorageUrlImage extends StatelessWidget {
  final double radius;
  final String path;
  final Widget fallback;

  const _StorageUrlImage({
    required this.radius,
    required this.path,
    required this.fallback,
  });

  Future<String> _url() async {
    final ref = FirebaseStorage.instance.ref().child(path);
    return await ref.getDownloadURL().timeout(const Duration(seconds: 20));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: _url(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: radius * 0.65,
              height: radius * 0.65,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Icon(Icons.broken_image_outlined, color: cs.error, size: radius * 0.9),
          );
        }
        final u = (snap.data ?? '').trim();
        if (u.isEmpty) return Center(child: fallback);
        return Image.network(
          u,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) {
            return Center(
              child: Icon(Icons.broken_image_outlined, color: cs.error, size: radius * 0.9),
            );
          },
          loadingBuilder: (context, child, loading) {
            if (loading == null) return child;
            return Center(
              child: SizedBox(
                width: radius * 0.65,
                height: radius * 0.65,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        );
      },
    );
  }
}

