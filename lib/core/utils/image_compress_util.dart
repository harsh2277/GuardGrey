import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressUtil {
  ImageCompressUtil._();

  static const int skipCompressionBytes = 200 * 1024;
  static const int defaultQuality = 65;
  static const int maxDimension = 1024;

  static Future<File> compressImage(
    File image, {
    int quality = defaultQuality,
    int minWidth = maxDimension,
    int minHeight = maxDimension,
  }) async {
    if (!await image.exists()) {
      return image;
    }

    final originalBytes = await image.length();
    if (originalBytes <= skipCompressionBytes) {
      return image;
    }

    final format = _targetFormatFor(image.path);
    final targetPath = _targetPathFor(image.path, format);
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
      keepExif: false,
    );

    if (compressedBytes == null || compressedBytes.isEmpty) {
      return image;
    }

    if (compressedBytes.length >= originalBytes) {
      return image;
    }

    return _writeCompressedFile(targetPath, compressedBytes);
  }

  static CompressFormat _targetFormatFor(String path) {
    switch (_extensionFor(path)) {
      case '.png':
      case '.jpg':
      case '.jpeg':
        return CompressFormat.webp;
      default:
        return CompressFormat.jpeg;
    }
  }

  static String _targetPathFor(String sourcePath, CompressFormat format) {
    final directory = Directory.systemTemp.path;
    final fileName = _fileNameWithoutExtension(sourcePath);
    final extension = switch (format) {
      CompressFormat.png => '.png',
      CompressFormat.webp => '.webp',
      _ => '.jpg',
    };
    return '$directory/${fileName}_${DateTime.now().microsecondsSinceEpoch}$extension';
  }

  static Future<File> _writeCompressedFile(
    String targetPath,
    Uint8List compressedBytes,
  ) {
    final file = File(targetPath);
    return file.writeAsBytes(compressedBytes, flush: true);
  }

  static String _extensionFor(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '';
    }
    return path.substring(dotIndex).toLowerCase();
  }

  static String _fileNameWithoutExtension(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    final fileName = normalizedPath.substring(
      normalizedPath.lastIndexOf('/') + 1,
    );
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }
}
