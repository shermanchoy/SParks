import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

class ImageModerationService {
  static const _callableName = 'moderateChatImage';

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

  Future<bool> isImageAppropriate(List<int> imageBytes) async {
    final r = await getModerationResult(imageBytes);
    return r.allowed;
  }
}
