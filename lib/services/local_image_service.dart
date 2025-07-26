import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LocalImageService {
  static const String _imageBaseUrl = 'local://images/';
  static late String _imagesDirectory;
  static bool _initialized = false;

  /// Khởi tạo service
  static Future<void> initialize() async {
    if (_initialized) return;

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    _imagesDirectory = '${appDocDir.path}/recipe_images';

    // Tạo thư mục nếu chưa có
    final Directory imagesDir = Directory(_imagesDirectory);
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    _initialized = true;
    print('✅ LocalImageService initialized: $_imagesDirectory');
  }

  /// Upload ảnh và trả về URL local
  static Future<String> uploadImage(File imageFile) async {
    await initialize();

    try {
      // Tạo tên file unique
      final String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String localFilePath = '$_imagesDirectory/$fileName';

      // Copy file vào thư mục local
      await imageFile.copy(localFilePath);

      // Trả về URL local
      final String localUrl = '$_imageBaseUrl$fileName';
      print('✅ Ảnh đã được lưu: $localUrl');

      return localUrl;
    } catch (e) {
      throw Exception('Lỗi khi lưu ảnh: $e');
    }
  }

  /// Lấy đường dẫn file thực từ URL local
  static Future<String?> getLocalPath(String localUrl) async {
    await initialize();

    if (!localUrl.startsWith(_imageBaseUrl)) {
      return null;
    }

    final String fileName = localUrl.substring(_imageBaseUrl.length);
    final String filePath = '$_imagesDirectory/$fileName';

    if (await File(filePath).exists()) {
      return filePath;
    }

    return null;
  }

  /// Kiểm tra ảnh có tồn tại không
  static Future<bool> imageExists(String localUrl) async {
    final String? filePath = await getLocalPath(localUrl);
    return filePath != null && await File(filePath).exists();
  }

  /// Xóa ảnh
  static Future<void> deleteImage(String localUrl) async {
    final String? filePath = await getLocalPath(localUrl);
    if (filePath != null && await File(filePath).exists()) {
      await File(filePath).delete();
      print('🗑️ Đã xóa ảnh: $localUrl');
    }
  }

  /// Lấy tất cả ảnh trong thư mục
  static Future<List<String>> getAllImages() async {
    await initialize();

    final Directory imagesDir = Directory(_imagesDirectory);
    if (!await imagesDir.exists()) {
      return [];
    }

    final List<FileSystemEntity> files = await imagesDir.list().toList();
    final List<String> imageUrls = [];

    for (final file in files) {
      if (file is File) {
        final String fileName = path.basename(file.path);
        final String localUrl = '$_imageBaseUrl$fileName';
        imageUrls.add(localUrl);
      }
    }

    return imageUrls;
  }

  /// Dọn dẹp ảnh cũ (tùy chọn)
  static Future<void> cleanupOldImages({int maxAgeInDays = 30}) async {
    await initialize();

    final Directory imagesDir = Directory(_imagesDirectory);
    if (!await imagesDir.exists()) return;

    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
    final List<FileSystemEntity> files = await imagesDir.list().toList();

    for (final file in files) {
      if (file is File) {
        final FileStat stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          print('🧹 Đã xóa ảnh cũ: ${path.basename(file.path)}');
        }
      }
    }
  }

  /// Copy ảnh từ assets để test
  static Future<String> copyAssetImage(String assetPath) async {
    await initialize();

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      final String fileName = 'asset_${DateTime.now().millisecondsSinceEpoch}${path.extension(assetPath)}';
      final String localFilePath = '$_imagesDirectory/$fileName';

      final File localFile = File(localFilePath);
      await localFile.writeAsBytes(bytes);

      final String localUrl = '$_imageBaseUrl$fileName';
      print('✅ Đã copy asset vào local: $localUrl');

      return localUrl;
    } catch (e) {
      throw Exception('Lỗi khi copy asset: $e');
    }
  }

  /// Lấy thông tin về thư mục ảnh
  static Future<Map<String, dynamic>> getStorageInfo() async {
    await initialize();

    final Directory imagesDir = Directory(_imagesDirectory);
    if (!await imagesDir.exists()) {
      return {
        'path': _imagesDirectory,
        'exists': false,
        'fileCount': 0,
        'totalSize': 0,
      };
    }

    final List<FileSystemEntity> files = await imagesDir.list().toList();
    int totalSize = 0;
    int fileCount = 0;

    for (final file in files) {
      if (file is File) {
        final FileStat stat = await file.stat();
        totalSize += stat.size;
        fileCount++;
      }
    }

    return {
      'path': _imagesDirectory,
      'exists': true,
      'fileCount': fileCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}
