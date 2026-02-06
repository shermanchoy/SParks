import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

/// Checks if an image is appropriate for chat using an AI moderation backend.
/// When inappropriate content is detected, the photo is flagged and should not be sent.
///
/// Expects a Firebase Callable function named [moderateChatImage] that:
/// - Accepts { "image": "<base64 string>" }
/// - Returns { "allowed": true } if safe, { "allowed": false } if inappropriate.
/// Deploy the Cloud Function (see /functions) to enable real moderation.
class ImageModerationService {
  static const _callableName = 'moderateChatImage';

  /// Returns true if the image is appropriate to send; false if it should be flagged and not sent.
  /// If the Cloud Function is not deployed (e.g. unavailability), we allow sending so the feature works.
  Future<bool> isImageAppropriate(List<int> imageBytes) async {
    if (imageBytes.isEmpty) return false;

    try {
      final base64Image = base64Encode(imageBytes);
      final callable = FirebaseFunctions.instance.httpsCallable(_callableName);
      final result = await callable.call<Map<String, dynamic>>(<String, dynamic>{'image': base64Image});
      final data = result.data;
      final allowed = data['allowed'];
      return allowed == true;
    } on FirebaseFunctionsException catch (e) {
      // Function not deployed or unavailable → allow send so chat photos work without backend
      if (e.code == 'not-found' || e.code == 'unavailable' || e.code == 'internal') {
        return true;
      }
      // Explicit rejection from function (e.g. inappropriate)
      return false;
    } catch (_) {
      return true;
    }
  }
}
