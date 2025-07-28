import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import 'notification_service.dart';

class AutoNotificationService {
  static final AutoNotificationService _instance = AutoNotificationService._internal();
  factory AutoNotificationService() => _instance;
  AutoNotificationService._internal();

  final NotificationService _notificationService = NotificationService();

  // Gửi thông báo tự động khi có công thức mới
  Future<void> sendNewRecipeNotification(Recipe recipe) async {
    try {
      final title = "🍽️ Món mới đã có!";
      final body = "Khám phá ngay công thức \"${recipe.title}\" cùng tìm hiểu ngay!";

      final data = {
        'type': 'new_recipe',
        'recipe_id': recipe.id,
        'recipe_title': recipe.title,
        'recipe_category': recipe.category,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      // Gửi thông báo đến tất cả users qua topic
      bool success = await _notificationService.sendNotification(
        title: title,
        body: body,
        topic: 'new_recipes', // Topic mà tất cả users đã subscribe
        data: data,
      );

      if (success) {
        if (kDebugMode) {
          print('Auto notification sent for new recipe: ${recipe.title}');
        }
      } else {
        if (kDebugMode) {
          print('Failed to send auto notification for recipe: ${recipe.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending auto notification: $e');
      }
    }
  }

  // Gửi thông báo khi có cập nhật công thức
  Future<void> sendRecipeUpdateNotification(Recipe recipe) async {
    try {
      final title = "📝 Công thức đã được cập nhật";
      final body = "\"${recipe.title}\" vừa có những thay đổi mới. Xem ngay!";

      final data = {
        'type': 'recipe_update',
        'recipe_id': recipe.id,
        'recipe_title': recipe.title,
        'recipe_category': recipe.category,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      bool success = await _notificationService.sendNotification(
        title: title,
        body: body,
        topic: 'recipe_updates',
        data: data,
      );

      if (success && kDebugMode) {
        print('Update notification sent for recipe: ${recipe.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending update notification: $e');
      }
    }
  }

  // Gửi thông báo chào mừng user mới
  Future<void> sendWelcomeNotification(String userToken) async {
    try {
      final title = "🎉 Chào mừng đến với FoodYummy!";
      final body = "Khám phá hàng ngàn công thức nấu ăn ngon và dễ làm!";

      final data = {
        'type': 'welcome',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      await _notificationService.sendNotification(
        title: title,
        body: body,
        token: userToken,
        data: data,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending welcome notification: $e');
      }
    }
  }

  // Gửi thông báo theo chủ đề
  Future<void> sendCategoryNotification(String category, Recipe recipe) async {
    try {
      final title = "🍳 Món ${category} mới!";
      final body = "Thử ngay công thức \"${recipe.title}\" trong danh mục ${category}!";

      final data = {
        'type': 'category_recipe',
        'recipe_id': recipe.id,
        'recipe_title': recipe.title,
        'recipe_category': recipe.category,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      // Gửi đến topic theo category
      await _notificationService.sendNotification(
        title: title,
        body: body,
        topic: 'category_${category.toLowerCase().replaceAll(' ', '_')}',
        data: data,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending category notification: $e');
      }
    }
  }

  // Gửi thông báo tùy chỉnh từ admin
  Future<void> sendCustomNotification({
    required String title,
    required String body,
    String? recipeId,
    String? targetTopic,
  }) async {
    try {
      final data = <String, dynamic>{
        'type': 'custom',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      if (recipeId != null) {
        data['recipe_id'] = recipeId;
      }

      await _notificationService.sendNotification(
        title: title,
        body: body,
        topic: targetTopic ?? 'all_users',
        data: data,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending custom notification: $e');
      }
    }
  }
}
