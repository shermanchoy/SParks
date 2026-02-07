import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

/// Checks if an image is appropriate for chat using an AI moderation backend.
/// When inappropriate content is detected, the photo is flagged and should not be sent.
///
/// Expects a Firebase Callable function named [moderateChatImage] that:
/// - Accepts { "image": "<base64 string>" }
/// - Returns { "allowed": boolean, "containsCat": boolean } (containsCat for blur on desktop/web).
class ImageModerationService {
  static const _callableName = 'moderateChatImage';

  /// Returns (allowed, containsCat). Use for chat: one call gives both moderation and cat flag.
  /// Uses us-central1 to match deployed callable (required for web/Chrome).
  Future<({bool allowed, bool containsCat})> getModerationResult(List<int> imageBytes) async {
    if (imageBytes.isEmpty) return (allowed: false, containsCat: false);
    try {
      final base64Image = base64Encode(imageBytes);
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable(_callableName);
      final result = await callable.call(<String, dynamic>{'image': base64Image});
      final data = (result.data as Map<String, dynamic>?) ?? {};
      final allowed = data['allowed'] == true;
      final rawCat = data['containsCat'];
      final containsCat = rawCat == true || rawCat == 'true' || rawCat == 1;
      return (allowed: allowed, containsCat: containsCat);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'unavailable' || e.code == 'internal') {
        return (allowed: true, containsCat: false);
      }
      return (allowed: false, containsCat: false);
    } catch (_) {
      return (allowed: true, containsCat: false);
    }
  }

  /// Returns true if the image is appropriate to send; false if it should be flagged and not sent.
  Future<bool> isImageAppropriate(List<int> imageBytes) async {
    final r = await getModerationResult(imageBytes);
    return r.allowed;
  }
}
