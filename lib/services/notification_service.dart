import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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
        // Handle notification tap
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'foodyummy_channel',
      'FoodYummy Notifications',
      channelDescription: 'Notification channel for FoodYummy app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
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

  // Get access token using JWT
  Future<String?> _getAccessToken() async {
    try {
      final now = DateTime.now();
      final jwt = JWT({
        'iss': _clientEmail,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': 'https://oauth2.googleapis.com/token',
        'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
      });

      final token = jwt.sign(RSAPrivateKey(_privateKey), algorithm: JWTAlgorithm.RS256);

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

  // Send notification to all users (topic-based)
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

  // Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String title,
    required String body,
    required String userToken,
    Map<String, dynamic>? data,
  }) async {
    return await sendNotification(
      title: title,
      body: body,
      token: userToken,
      data: data,
    );
  }

  // Method for triggering new recipe notifications
  Future<void> triggerNewRecipeNotification({
    required String recipeTitle,
    required String recipeId,
    String? authorName,
  }) async {
    try {
      String title = "Công thức mới!";
      String body = authorName != null
        ? "$authorName đã thêm công thức: $recipeTitle"
        : "Công thức mới đã được thêm: $recipeTitle";

      // Send to all users topic
      await sendNotificationToAll(
        title: title,
        body: body,
        data: {
          'type': 'new_recipe',
          'recipe_id': recipeId,
          'recipe_title': recipeTitle,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (kDebugMode) {
        print('New recipe notification sent: $recipeTitle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending new recipe notification: $e');
      }
    }
  }

  // Method for triggering user activity notifications
  Future<void> triggerUserActivityNotification({
    required String title,
    required String body,
    required String targetUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // In a real app, you would get the user's FCM token from Firestore
      // For now, we'll send to a topic based on user ID
      await sendNotification(
        title: title,
        body: body,
        topic: 'user_$targetUserId',
        data: {
          'type': 'user_activity',
          'target_user_id': targetUserId,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      if (kDebugMode) {
        print('User activity notification sent to: $targetUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending user activity notification: $e');
      }
    }
  }

  // Method for triggering admin notifications
  Future<void> triggerAdminNotification({
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await sendNotification(
        title: title,
        body: body,
        topic: 'admin_notifications',
        data: {
          'type': 'admin',
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalData,
        },
      );

      if (kDebugMode) {
        print('Admin notification sent');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending admin notification: $e');
      }
    }
  }
}
