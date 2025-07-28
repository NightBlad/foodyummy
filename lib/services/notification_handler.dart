import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/menu_screen.dart';
import '../services/firestore_service.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  static BuildContext? _context;
  static final FirestoreService _firestoreService = FirestoreService();

  // Set context để có thể navigate
  static void setContext(BuildContext context) {
    _context = context;
  }

  // Handle notification tap khi app đang chạy
  static Future<void> handleNotificationTap(String? payload) async {
    if (payload == null || _context == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'new_recipe':
          await _handleNewRecipeNotification(data);
          break;
        case 'recipe_update':
          await _handleRecipeUpdateNotification(data);
          break;
        case 'general':
          await _handleGeneralNotification(data);
          break;
        default:
          // Navigate to main menu for unknown types
          await _navigateToMainMenu();
      }
    } catch (e) {
      print('Error handling notification tap: $e');
      // Navigate to main menu on error
      await _navigateToMainMenu();
    }
  }

  // Handle new recipe notification
  static Future<void> _handleNewRecipeNotification(Map<String, dynamic> data) async {
    final recipeId = data['recipe_id'] as String?;
    if (recipeId != null && _context != null) {
      try {
        // Lấy recipe từ Firestore bằng ID
        final recipe = await _firestoreService.getRecipe(recipeId);

        if (recipe != null) {
          Navigator.of(_context!).push(
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        } else {
          // Nếu không tìm thấy recipe, chuyển đến menu chính
          await _navigateToMainMenu();
          _showSnackBar('Không tìm thấy món ăn này');
        }
      } catch (e) {
        print('Error fetching recipe: $e');
        await _navigateToMainMenu();
        _showSnackBar('Có lỗi xảy ra khi tải món ăn');
      }
    }
  }

  // Handle recipe update notification
  static Future<void> _handleRecipeUpdateNotification(Map<String, dynamic> data) async {
    final recipeId = data['recipe_id'] as String?;
    if (recipeId != null && _context != null) {
      try {
        final recipe = await _firestoreService.getRecipe(recipeId);

        if (recipe != null) {
          Navigator.of(_context!).push(
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        } else {
          await _navigateToMainMenu();
          _showSnackBar('Món ăn đã được cập nhật không còn tồn tại');
        }
      } catch (e) {
        print('Error fetching updated recipe: $e');
        await _navigateToMainMenu();
      }
    }
  }

  // Handle general notification
  static Future<void> _handleGeneralNotification(Map<String, dynamic> data) async {
    // Navigate to main menu for general notifications
    await _navigateToMainMenu();

    final message = data['message'] as String?;
    if (message != null) {
      _showSnackBar(message);
    }
  }

  // Navigate to main menu
  static Future<void> _navigateToMainMenu() async {
    if (_context != null) {
      Navigator.of(_context!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RecipeScreen()),
        (route) => false,
      );
    }
  }

  // Show snackbar message
  static void _showSnackBar(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Handle Firebase messaging when app is opened from terminated state
  static Future<void> handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await handleRemoteMessage(initialMessage);
    }
  }

  // Handle remote message from Firebase
  static Future<void> handleRemoteMessage(RemoteMessage message) async {
    final payload = json.encode(message.data);
    await handleNotificationTap(payload);
  }
}
