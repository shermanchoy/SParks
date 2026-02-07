import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_functions/cloud_functions.dart';

import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart' as platform_utils;
import 'cat_detection_service_io_stub.dart'
    if (dart.library.io) 'cat_detection_service_io.dart' as io_impl;

/// Detects whether an image contains a cat (ML Kit on mobile, Cloud Vision on desktop/web).
class CatDetectionService {
  static const _callableName = 'detectCatInImage';

  /// Returns true if [imageBytes] contains a cat. Uses ML Kit on Android/iOS, Cloud callable on Windows/web.
  Future<bool> containsCatFromBytes(List<int> imageBytes) async {
    if (imageBytes.isEmpty) return false;
    if (kIsWeb || !platform_utils.isMobilePlatform) {
      return _containsCatViaCloud(imageBytes);
    }
    return io_impl.detectCatFromBytesOnMobile(imageBytes);
  }

  Future<bool> _containsCatViaCloud(List<int> imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable(_callableName);
      final result = await callable.call(<String, dynamic>{'image': base64Image});
      final data = (result.data as Map<String, dynamic>?) ?? {};
      final raw = data['containsCat'];
      return raw == true || raw == 'true' || raw == 1;
    } catch (_) {
      return false;
    }
  }
}
