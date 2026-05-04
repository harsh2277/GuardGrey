import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:guardgrey/core/utils/image_compress_util.dart';

class UploadedImageReference {
  const UploadedImageReference({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class FirebaseStorageService {
  FirebaseStorageService._({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  static final FirebaseStorageService instance = FirebaseStorageService._();

  static const int maxImages = 5;

  final FirebaseStorage _storage;

  Future<List<String>> uploadImages({
    required String folder,
    required List<XFile> files,
  }) async {
    final uploadedReferences = await uploadImageReferences(
      folder: folder,
      files: files,
    );
    return uploadedReferences
        .map((item) => item.downloadUrl)
        .toList(growable: false);
  }

  Future<List<UploadedImageReference>> uploadImageReferences({
    required String folder,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) {
      return const <UploadedImageReference>[];
    }
    if (files.length > maxImages) {
      throw ArgumentError('Only up to $maxImages images are allowed.');
    }

    final uploadedReferences = <UploadedImageReference>[];
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final originalFile = File(file.path);
      final uploadFile = await ImageCompressUtil.compressImage(originalFile);
      final bytes = await uploadFile.readAsBytes();
      final extension = _extensionFor(uploadFile.path);
      final path =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$index$extension';
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: _contentTypeFor(extension),
      );
      final task = await ref.putData(bytes, metadata);
      uploadedReferences.add(
        UploadedImageReference(
          downloadUrl: await task.ref.getDownloadURL(),
          storagePath: task.ref.fullPath,
        ),
      );
      if (uploadFile.path != originalFile.path && await uploadFile.exists()) {
        await uploadFile.delete();
      }
    }
    return uploadedReferences;
  }

  String _extensionFor(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex).toLowerCase();
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
