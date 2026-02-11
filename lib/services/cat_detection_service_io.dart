import 'dart:io';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

const _minConfidence = 0.15;

bool _isCatLabel(String label) {
  final lower = label.trim().toLowerCase();
  if (lower == 'cat' || lower == 'kitten' || lower == 'tabby') return true;
  if (lower.contains('cat')) return true;
  return false;
}

bool _isPng(List<int> bytes) {
  if (bytes.length < 8) return false;
  return bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}

Future<bool> detectCatFromBytesOnMobile(List<int> imageBytes) async {
  if (imageBytes.isEmpty) return false;
  final dir = await Directory.systemTemp.createTemp('cat_');
  final ext = _isPng(imageBytes) ? 'png' : 'jpg';
  final file = File('${dir.path}/img.$ext');
  try {
    await file.writeAsBytes(imageBytes);
    return await _containsCatFromFile(file.path);
  } finally {
    await dir.delete(recursive: true);
  }
}

Future<bool> _containsCatFromFile(String filePath) async {
  if (filePath.trim().isEmpty) return false;
  final file = File(filePath);
  if (!await file.exists()) return false;
  ImageLabeler? labeler;
  try {
    final inputImage = InputImage.fromFilePath(filePath);
    labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: _minConfidence));
    final labels = await labeler.processImage(inputImage);
    for (final label in labels) {
      if (_isCatLabel(label.label) && label.confidence >= _minConfidence) {
        return true;
      }
    }
    return false;
  } catch (_) {
    return false;
  } finally {
    await labeler?.close();
  }
}
