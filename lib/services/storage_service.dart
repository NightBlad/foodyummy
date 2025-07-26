import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File imageFile, String storagePath) async {
    try {
      // Tạo tên file unique
      final String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final Reference ref = _storage.ref().child('recipe_images/$fileName');

      // Upload file với metadata
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded_by': 'foodyummy_app'},
        ),
      );

      // Đợi upload hoàn thành
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Lấy download URL
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
        final Reference ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      // Ignore error if image doesn't exist
      print('Không thể xóa ảnh: $e');
    }
  }
}
