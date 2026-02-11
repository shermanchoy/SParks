import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:cloud_functions/cloud_functions.dart';

import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart' as platform_utils;
import 'cat_detection_service_io_stub.dart'
    if (dart.library.io) 'cat_detection_service_io.dart' as io_impl;

class CatDetectionService {
  static const _callableName = 'detectCatInImage';

  /// Prefer Cloud (Vision API) for consistent cat detection; fall back to
  /// on-device ML Kit only when cloud fails (e.g. network) on mobile.
  Future<bool> containsCatFromBytes(List<int> imageBytes) async {
    if (imageBytes.isEmpty) return false;
    try {
      final fromCloud = await _containsCatViaCloud(imageBytes);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[CatDetection] Cloud returned containsCat: $fromCloud');
      }
      return fromCloud;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[CatDetection] Cloud failed: $e');
        // ignore: avoid_print
        print('[CatDetection] Stack: $st');
      }
      if (kIsWeb || !platform_utils.isMobilePlatform) return false;
      final fallback = await io_impl.detectCatFromBytesOnMobile(imageBytes);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[CatDetection] Mobile fallback returned: $fallback');
      }
      return fallback;
    }
  }

  Future<bool> _containsCatViaCloud(List<int> imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = functions.httpsCallable(_callableName);
    final result = await callable.call(<String, dynamic>{'image': base64Image});
    final data = (result.data as Map<String, dynamic>?) ?? {};
    final raw = data['containsCat'];
    return raw == true || raw == 'true' || raw == 1;
  }
}
