import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class HybridStorageService {

  /// Upload ảnh vào thư mục project (không cần Firebase)
  Future<String> uploadImage(File imageFile, String storagePath) async {
    try {
      // Lưu ảnh vào thư mục assets/images của project
      final String localPath = await _saveToProjectAssets(imageFile);

      print('✅ Đã lưu ảnh vào project: $localPath');
      return localPath;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: $e');
    }
  }

  /// Lưu ảnh vào thư mục assets/images của project
  Future<String> _saveToProjectAssets(File imageFile) async {
    try {
      // Tạo tên file unique
      final String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Lấy đường dẫn thư mục assets/images
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String projectImagesPath = '${appDocDir.path}/project_images';

      // Tạo thư mục nếu chưa có
      final Directory imagesDir = Directory(projectImagesPath);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Copy file vào thư mục project
      final String localFilePath = '$projectImagesPath/$fileName';
      final File localFile = await imageFile.copy(localFilePath);

      // Trả về relative path để dễ sử dụng
      return 'assets/images/$fileName';

    } catch (e) {
      throw Exception('Lỗi lưu ảnh vào project: $e');
    }
  }

  /// Copy ảnh từ app documents về assets/images để hiển thị
  Future<void> _copyToAssetsFolder(String fileName, File sourceFile) async {
    try {
      // Lấy đường dẫn thư mục project
      final String currentDir = Directory.current.path;
      final String assetsPath = '$currentDir/assets/images';

      // Tạo thư mục nếu chưa có
      final Directory assetsDir = Directory(assetsPath);
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      // Copy file
      final String targetPath = '$assetsPath/$fileName';
      await sourceFile.copy(targetPath);

      print('📂 Đã copy ảnh vào assets: $targetPath');
    } catch (e) {
      print('⚠️ Không thể copy vào assets: $e');
    }
  }

  /// Lấy đường dẫn ảnh để hiển thị
  Future<String> getImagePath(String imagePath) async {
    try {
      // Nếu là đường dẫn assets
      if (imagePath.startsWith('assets/images/')) {
        // Kiểm tra trong app documents trước
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = imagePath.split('/').last;
        final String localPath = '${appDocDir.path}/project_images/$fileName';

        if (await File(localPath).exists()) {
          return localPath;
        }
      }

      // Nếu là đường dẫn local đầy đủ
      if (imagePath.contains('/project_images/') && await File(imagePath).exists()) {
        return imagePath;
      }

      // Fallback
      return imagePath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Xóa ảnh
  Future<void> deleteImage(String imagePath) async {
    try {
      if (imagePath.startsWith('assets/images/')) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = imagePath.split('/').last;
        final String localPath = '${appDocDir.path}/project_images/$fileName';

        final File localFile = File(localPath);
        if (await localFile.exists()) {
          await localFile.delete();
          print('🗑️ Đã xóa ảnh: $localPath');
        }
      }
    } catch (e) {
      print('⚠️ Lỗi xóa ảnh: $e');
    }
  }

  /// Lấy danh sách tất cả ảnh trong project
  Future<List<String>> getAllProjectImages() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String projectImagesPath = '${appDocDir.path}/project_images';
      final Directory imagesDir = Directory(projectImagesPath);

      if (!await imagesDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await imagesDir.list().toList();
      return files
          .where((file) => file is File)
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('⚠️ Lỗi lấy danh sách ảnh: $e');
      return [];
    }
  }

  /// Dọn dẹp ảnh cũ (chạy định kỳ)
  Future<void> cleanupOldImages() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String projectImagesPath = '${appDocDir.path}/project_images';
      final Directory imagesDir = Directory(projectImagesPath);

      if (!await imagesDir.exists()) {
        return;
      }

      final List<FileSystemEntity> files = await imagesDir.list().toList();
      final DateTime cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      for (var file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            print('🧹 Đã xóa ảnh cũ: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('⚠️ Lỗi dọn dẹp ảnh: $e');
    }
  }
}
