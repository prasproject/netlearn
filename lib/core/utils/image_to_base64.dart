import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageToBase64 {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickFromGalleryAndEncode({
    int maxWidth = 900,
    int maxHeight = 900,
    int quality = 60,
  }) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final compressed = await _compressBytes(
      bytes,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );
    return base64Encode(compressed);
  }

  static Future<String?> pickFromCameraAndEncode({
    int maxWidth = 900,
    int maxHeight = 900,
    int quality = 60,
  }) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final compressed = await _compressBytes(
      bytes,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );
    return base64Encode(compressed);
  }

  static Future<Uint8List> _compressBytes(
    Uint8List bytes, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    // If compression fails, fall back to original bytes.
    final out = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality.clamp(10, 95),
      format: CompressFormat.jpeg,
    );
    return Uint8List.fromList(out.isEmpty ? bytes : out);
  }
}

