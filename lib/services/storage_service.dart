import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Quick connectivity/rules probe for Firebase Storage.
  ///
  /// Returns a short human-readable status string.
  Future<String> probe({String? uid}) async {
    final p = (uid != null && uid.trim().isNotEmpty)
        ? 'profile_photos/${uid.trim()}/__probe__.txt'
        : '__probe__/ping.txt';
    try {
      // Probe a path that should be allowed by your app's rules.
      // We expect this to fail with "object-not-found" (that's GOOD) if rules/network are OK.
      await _storage.ref().child(p).getDownloadURL().timeout(const Duration(seconds: 10));
      return 'Storage reachable (probe file exists). Path: $p';
    } on TimeoutException {
      return 'Cannot reach Firebase Storage (timeout). Path: $p';
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return 'Storage reachable (object-not-found is expected for probe). Path: $p';
      }
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        return 'Storage reachable but blocked by rules (${e.code}). Path: $p';
      }
      return 'Storage error: ${e.code}. Path: $p';
    } catch (e) {
      return 'Storage error: $e. Path: $p';
    }
  }

  /// Uploads a profile photo and returns:
  /// - photoUrl: public download URL
  /// - photoPath: storage path (for later deletion/replacement)
  Future<({String photoUrl, String photoPath})> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'profile_photos/$uid/$ts.jpg';
    final ref = _storage.ref().child(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final sub = task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (total <= 0) return;
      final p = snap.bytesTransferred / total;
      onProgress?.call(p.clamp(0.0, 1.0));
    });

    try {
      // Avoid hanging forever if network/storage stalls.
      await task.timeout(const Duration(seconds: 35), onTimeout: () async {
        try {
          await task.cancel();
        } catch (_) {}
        throw TimeoutException(
          'Upload timed out. Likely: (1) network blocks Firebase Storage, or (2) Storage rules/App Check blocks uploads.',
        );
      });
    } on FirebaseException catch (e) {
      // Surface the exact Storage error (permission-denied, unauthenticated, etc).
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: e.message ?? 'Firebase Storage error: ${e.code}',
      );
    } finally {
      await sub.cancel();
    }

    final url = await ref.getDownloadURL().timeout(const Duration(seconds: 30));
    return (photoUrl: url, photoPath: path);
  }

  /// Uploads a chat photo and returns the public download URL.
  /// Path: chat_photos/{chatId}/{timestamp}_{senderId}.jpg
  Future<String> uploadChatPhoto({
    required String chatId,
    required String senderId,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'chat_photos/$chatId/${ts}_$senderId.jpg';
    final ref = _storage.ref().child(path);

    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final sub = task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (total <= 0) return;
      final p = snap.bytesTransferred / total;
      onProgress?.call(p.clamp(0.0, 1.0));
    });

    try {
      await task.timeout(const Duration(seconds: 35), onTimeout: () async {
        try {
          await task.cancel();
        } catch (_) {}
        throw TimeoutException(
          'Chat photo upload timed out.',
        );
      });
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: e.message ?? 'Firebase Storage error: ${e.code}',
      );
    } finally {
      await sub.cancel();
    }

    final url = await ref.getDownloadURL().timeout(const Duration(seconds: 30));
    return url;
  }

  Future<void> deleteByPath(String? path) async {
    final p = path?.trim() ?? '';
    if (p.isEmpty) return;
    // Best-effort cleanup. If the object doesn't exist (or rules deny), don't crash UX.
    try {
      await _storage.ref().child(p).delete().timeout(const Duration(seconds: 20));
    } catch (_) {}
  }
}
