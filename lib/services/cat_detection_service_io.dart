import 'dart:io';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

const _minConfidence = 0.25;

/// True if the label is or contains "cat" (e.g. "Cat", "Domestic cat", "Tabby cat").
bool _isCatLabel(String label) {
  final lower = label.trim().toLowerCase();
  if (lower == 'cat' || lower == 'kitten' || lower == 'tabby') return true;
  if (lower.contains('cat')) return true; // "domestic cat", "tabby cat", etc.
  return false;
}

Future<bool> detectCatFromBytesOnMobile(List<int> imageBytes) async {
  if (imageBytes.isEmpty) return false;
  final dir = await Directory.systemTemp.createTemp('cat_');
  final file = File('${dir.path}/img.jpg');
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
