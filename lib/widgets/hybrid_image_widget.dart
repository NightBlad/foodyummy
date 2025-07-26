import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/local_image_service.dart';

class HybridImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const HybridImageWidget({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Kiểm tra imagePath có hợp lệ không
    if (imagePath.isEmpty || imagePath == 'null' || imagePath.length < 5) {
      return _buildErrorWidget();
    }

    // Nếu là URL local mới (local://images/)
    if (imagePath.startsWith('local://images/')) {
      return _buildLocalUrlImage();
    }

    // Nếu là đường dẫn assets/images từ project
    if (imagePath.startsWith('assets/images/')) {
      return _buildProjectImage();
    }

    // Nếu là đường dẫn local file đầy đủ
    if (imagePath.contains('/recipe_images/') && !imagePath.startsWith('http')) {
      return _buildLocalImage();
    }

    // Nếu là Firebase URL hợp lệ (backup)
    if (imagePath.startsWith('https://') && imagePath.contains('.')) {
      return _buildNetworkImage();
    }

    // Fallback cho URL không hợp lệ
    return _buildErrorWidget();
  }

  // Widget cho URL local mới
  Widget _buildLocalUrlImage() {
    return FutureBuilder<String?>(
      future: LocalImageService.getLocalPath(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasData && snapshot.data != null) {
          final File imageFile = File(snapshot.data!);
          return FutureBuilder<bool>(
            future: imageFile.exists(),
            builder: (context, existsSnapshot) {
              if (existsSnapshot.data == true) {
                return Image.file(
                  imageFile,
                  width: width,
                  height: height,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget();
                  },
                );
              }
              return _buildErrorWidget();
            },
          );
        }

        return _buildErrorWidget();
      },
    );
  }

  Widget _buildProjectImage() {
    return FutureBuilder<String>(
      future: _getActualImagePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final File imageFile = File(snapshot.data!);
          return FutureBuilder<bool>(
            future: imageFile.exists(),
            builder: (context, existsSnapshot) {
              if (existsSnapshot.data == true) {
                return Image.file(
                  imageFile,
                  width: width,
                  height: height,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorWidget();
                  },
                );
              }
              return _buildErrorWidget();
            },
          );
        }

        return _buildErrorWidget();
      },
    );
  }

  Future<String> _getActualImagePath() async {
    try {
      // Lấy tên file từ assets path
      final String fileName = imagePath.split('/').last;

      // Tìm file trong thư mục project_images
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath = '${appDocDir.path}/project_images/$fileName';

      if (await File(localPath).exists()) {
        return localPath;
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildLocalImage() {
    final File imageFile = File(imagePath);

    return FutureBuilder<bool>(
      future: imageFile.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.data == true) {
          return Image.file(
            imageFile,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          );
        }

        return _buildErrorWidget();
      },
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 50,
          ),
        );
  }
}
