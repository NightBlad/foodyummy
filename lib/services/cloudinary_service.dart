import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic('dkjxd1qdx', 'nguyenhakien', cache: false);

  Future<String> uploadImage(File imageFile) async {
    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
    );
    return response.secureUrl;
  }

  // Helper method to validate image file
  static bool isValidImageFile(File file) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final fileName = file.path.toLowerCase();
    return validExtensions.any((ext) => fileName.endsWith(ext));
  }

  // Helper method to check file size (optional)
  static Future<bool> isValidFileSize(File file, {int maxSizeMB = 10}) async {
    final fileSizeInBytes = await file.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    return fileSizeInMB <= maxSizeMB;
  }
}
