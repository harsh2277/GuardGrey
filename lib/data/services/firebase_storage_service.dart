import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
    if (files.isEmpty) {
      return const <String>[];
    }
    if (files.length > maxImages) {
      throw ArgumentError('Only up to $maxImages images are allowed.');
    }

    final uploadedUrls = <String>[];
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final bytes = await file.readAsBytes();
      final extension = _extensionFor(file.name);
      final path =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$index$extension';
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: _contentTypeFor(extension),
      );
      final task = await ref.putData(bytes, metadata);
      uploadedUrls.add(await task.ref.getDownloadURL());
    }
    return uploadedUrls;
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
