import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'notification_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Service Account thông tin
  static const String _projectId = 'foodyummy-3d887';
  static const String _privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDKwXZONk4ZVUUC
tQn/wkIY4L6BJO1Lc5rJu7FsLrljgExDLlqAPZhOO2XcNo5hY2pudqEbf5YftfJV
fa272HZ9PHm7xYnzU3a/RiniQ2IsPBot72p16e16/PisKsj3r0sFsUecdf7laJj2
bySFGfZpgTulJoiqxGnr+K2sYjpWyvoR9aQDrkaf7AdU2LPoFjBzj9mpXRmAJA7n
naLMUy3V+Dbhb0tpgJpi+JbW5/jw0RUbRHxwRf7up7R8TU2TI8a4cWAU36UcoH2U
sKZEF6Jv+pOCulpGZ369PlcRX6TZXlW/knXhTDr/YGbKBb035L9ErTl58WIiMPJ2
rjskJi5jAgMBAAECggEAW/1mVZnh2TCMvOuye62BG5RsGl/MoZzzr29O0gxo5DID
Z7+SI/jOL0BXuI+wDZNzaGa+NaGvVPfR2OPKfR16tNtJR94Z9qH5kFKfEh8MXZFv
N0QWgyT9L/2yPTq0L1wCp7SFDwGiAidwru5CHXloCPovO4C+JOw0OnF7Kmjumw1x
Kr0eM/UBfbYSdLK0B7AXEgtRdI6L1Oa7s8bJHYxnJD2DQD+G6htJ12xN/3zXxnhc
govwoXjq3dQ2W/9M3Bq5aDhbdP9NWsbam8eRNXrNYunRn4aLymjoigwyzLvpTVFB
UfhggFulAYsTlqETN6Pk/UhkRDP/1o6JPDqaIb7jMQKBgQD0D7HS4KlHEwtuq2b1
FMPSHt3DulJx3ucI3leGGyTsANC9BhggfRqLg49RbfiIoowe7nQ8sgGSgAnld0vC
NMEMqXAhBg5unt7Z8VKWvtUC8ftmiTg5yoFEvGkBR18o7tLAnyfztbi1/P3weez6
5Dfyksrm4U3c/NNy3tx6gRHAPQKBgQDUrIKXLze2xnIDI8K0Wk2cAmarVHJCoDwb
EumaIdVzeHCKxKxTFQRxK/wAjTEncHuotvF0eVMteMQ9mbKwjOYQHN5UCV6QPN9D
A9Qkc0QURrZZt1U5h6d0MkfsLL+rjTHCzIsQ8lroaAeaaDuGuXvA47R4rikf6Jy2
YN+ycf7zHwKBgQDROg8xAAY+dxYq5ufZnNaO8IUfAUEie3vGf4262tRZOg24rlvK
plU2Wy9nGIai4+6JqdSeH9/3LqrNO+sHb2A8MZl9xgpjTPExF4+8yZYk8zuZWHOK
H4+YVIkUXpI2rh6goRCH/jZ+VYeBO5UsNK+91Zf6PBYbJ+dBp8qNfs6v5QKBgBw0
AGFyNo47hNUbwe9O5mng+6KO4VQqka35dRcmk3rrpukQKdYevGcRsSqVjsYvKYb3
M9ABYuFt2YBdyI+XL89FNMqqL2srV2Q4tsJastWJhxcgs+GcNr23CUitqoFiiQ3P
OEX4DcwyN4fneLVmFZ4/1CgI2JVNsLKS6Ddu3KN7AoGBAJqpF4JTbZkFMwDqD8WL
9Nsl1qKFnASpKPnJpTtoj+i2rwU/iS2C8TQxRA9UZsJlZFG/TUie3SA8cgnJRW8v
B5/0ZGlWtuOIUM9Iq2qOpg3K5Dux/F1hikP41QKBHFrLmDpiuM+2m8mE0E3lIYkp
Btiw7U1rguVlCZV2ErpcDDAy
-----END PRIVATE KEY-----''';
  static const String _clientEmail = 'firebase-adminsdk-fbsvc@foodyummy-3d887.iam.gserviceaccount.com';

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission
    await requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Setup Firebase messaging
    await _setupFirebaseMessaging();

    // Auto-subscribe to all_users topic để nhận thông báo từ admin
    await _autoSubscribeToTopics();
  }

  // Auto subscribe to important topics
  Future<void> _autoSubscribeToTopics() async {
    try {
      // Subscribe to all users topic
      await subscribeToTopic('all_users');

      // Subscribe to new recipes topic
      await subscribeToTopic('new_recipes');

      if (kDebugMode) {
        print('Auto-subscribed to notification topics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error auto-subscribing to topics: $e');
      }
    }
  }

  Future<void> requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap với NotificationHandler
        NotificationHandler.handleNotificationTap(response.payload);
      },
    );
  }

  Future<void> _setupFirebaseMessaging() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle notification tap when app is terminated or in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      // Navigate to specific screen based on message data
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Create action buttons for new recipe notifications
    List<AndroidNotificationAction> actions = [];
    if (message.data['type'] == 'new_recipe') {
      actions.add(
        const AndroidNotificationAction(
          'explore_recipe',
          'Tìm hiểu ngay',
          icon: DrawableResourceAndroidBitmap('ic_notification'),
        ),
      );
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'foodyummy_channel',
      'FoodYummy Notifications',
      channelDescription: 'Notification channel for FoodYummy app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      actions: actions,
      styleInformation: const BigTextStyleInformation(''),
      icon: 'ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification'),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  // Send notification using HTTP v1 API
  Future<bool> sendNotification({
    required String title,
    required String body,
    String? token,
    String? topic,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get access token
      String? accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('Failed to get access token');
      }

      // Prepare the message
      Map<String, dynamic> message = {
        'message': {
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }
      };

      // Add target (either token or topic)
      if (token != null) {
        message['message']['token'] = token;
      } else if (topic != null) {
        message['message']['topic'] = topic;
      } else {
        throw Exception('Either token or topic must be provided');
      }

      // Send the request
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Notification sent successfully');
          print('Response: ${response.body}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to send notification: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      return false;
    }
  }

  // Generate access token using JWT
  Future<String?> _getAccessToken() async {
    try {
      // Create JWT payload
      final jwt = JWT({
        'iss': _clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });

      // Sign the JWT
      final token = jwt.sign(RSAPrivateKey(_privateKey));

      // Exchange JWT for access token
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        if (kDebugMode) {
          print('Failed to get access token: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting access token: $e');
      }
      return null;
    }
  }

  // Subscribe user to category-specific topics
  Future<void> subscribeToCategories(List<String> categories) async {
    try {
      for (String category in categories) {
        final topicName = 'category_${category.toLowerCase().replaceAll(' ', '_')}';
        await subscribeToTopic(topicName);
      }

      // Also subscribe to recipe updates
      await subscribeToTopic('recipe_updates');

      if (kDebugMode) {
        print('Subscribed to category topics: $categories');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to category topics: $e');
      }
    }
  }

  // Show immediate notification for foreground apps
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'foodyummy_channel',
      'FoodYummy Notifications',
      channelDescription: 'Notification channel for FoodYummy app',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data != null ? json.encode(data) : null,
    );
  }

  // Thêm các method bị thiếu cho backward compatibility
  Future<bool> sendNotificationToUser({
    required String userToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await sendNotification(
      title: title,
      body: body,
      token: userToken,
      data: data,
    );
  }

  Future<bool> sendNotificationToAll({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await sendNotification(
      title: title,
      body: body,
      topic: 'all_users',
      data: data,
    );
  }

  // Trigger notification for new recipe - Simplified version (chỉ local notification)
  Future<bool> triggerNewRecipeNotification({
    required String recipeTitle,
    required String recipeId,
    String? category,
  }) async {
    try {
      // Chỉ hiển thị local notification đơn giản, không cần FCM
      await showSimpleLocalNotification(
        title: "🍽️ Món mới đã thêm thành công!",
        body: "\"$recipeTitle\" đã được thêm vào bộ sưu tập${category != null ? ' trong danh mục $category' : ''}",
        recipeId: recipeId,
      );

      if (kDebugMode) {
        print('Local notification sent for recipe: $recipeTitle');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error in triggerNewRecipeNotification: $e');
      }
      return false;
    }
  }

  // Hiển thị local notification đơn giản và ổn định
  Future<void> showSimpleLocalNotification({
    required String title,
    required String body,
    required String recipeId,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'foodyummy_simple',
        'FoodYummy Notifications',
        channelDescription: 'Thông báo từ ứng dụng FoodYummy',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        autoCancel: true,
        enableVibration: true,
        playSound: true,
        // Bỏ custom sound, dùng sound mặc định
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Bỏ custom sound cho iOS
        badgeNumber: 1,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: json.encode({
          'type': 'new_recipe',
          'recipe_id': recipeId,
        }),
      );

      if (kDebugMode) {
        print('Simple notification displayed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing simple notification: $e');
      }
    }
  }

  // Show local notification for new recipe - Simplified version
  Future<void> showLocalNotificationForNewRecipe({
    required String title,
    required String body,
    required String recipeId,
  }) async {
    // Gọi method đơn giản hơn
    await showSimpleLocalNotification(
      title: title,
      body: body,
      recipeId: recipeId,
    );
  }

  // Alternative simple notification method - Updated
  Future<bool> sendSimpleNotification({
    required String title,
    required String body,
    String? recipeId,
  }) async {
    try {
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'foodyummy_basic',
          'FoodYummy Basic Notifications',
          channelDescription: 'Thông báo cơ bản từ FoodYummy',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          // Không dùng custom sound
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: recipeId != null ? json.encode({
          'type': 'new_recipe',
          'recipe_id': recipeId,
        }) : null,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending simple notification: $e');
      }
      return false;
    }
  }
}
