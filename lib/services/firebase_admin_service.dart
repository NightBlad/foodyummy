import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAdminService {
  static final FirebaseAdminService _instance = FirebaseAdminService._internal();
  factory FirebaseAdminService() => _instance;
  FirebaseAdminService._internal();

  // Service account credentials
  final String _projectId = 'foodyummy-3d887';
  final String _privateKey = '''-----BEGIN PRIVATE KEY-----
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
  final String _clientEmail = 'firebase-adminsdk-fbsvc@foodyummy-3d887.iam.gserviceaccount.com';

  // Gửi notification đến một device cụ thể
  Future<bool> sendNotificationToDevice({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      final url = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'notification': {
              'channel_id': 'foodyummy_channel',
              'color': '#FF6B6B',
              'icon': 'ic_launcher',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'badge': 1,
                'sound': 'default',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        return true;
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Gửi notification đến một topic
  Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      final url = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

      final message = {
        'message': {
          'topic': topic,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'notification': {
              'channel_id': 'foodyummy_channel',
              'color': '#FF6B6B',
              'icon': 'ic_launcher',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {
                  'title': title,
                  'body': body,
                },
                'badge': 1,
                'sound': 'default',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent to topic successfully');
        return true;
      } else {
        print('Failed to send notification to topic: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification to topic: $e');
      return false;
    }
  }

  // Gửi notification về công thức mới
  Future<bool> sendNewRecipeNotification({
    required String recipeTitle,
    required String recipeId,
    required String authorName,
  }) async {
    return await sendNotificationToTopic(
      topic: 'all_users',
      title: '🍽️ Công thức mới từ $authorName',
      body: 'Khám phá công thức "$recipeTitle" ngay bây giờ!',
      data: {
        'type': 'new_recipe',
        'recipe_id': recipeId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  // Gửi thông báo cho admin
  Future<bool> sendAdminNotification({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    return await sendNotificationToTopic(
      topic: 'admin_notifications',
      title: title,
      body: body,
      data: data ?? {},
    );
  }

  // Lấy access token từ service account
  Future<String?> _getAccessToken() async {
    try {
      // Đây là phiên bản đơn giản - trong production cần implement JWT signing
      // Hiện tại sẽ return null và sử dụng Firebase Functions thay thế
      print('Access token generation would be implemented here');
      print('For now, use Firebase Functions or backend service');
      return null;
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  // Lưu FCM token của user vào Firestore
  Future<void> saveUserFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token saved to Firestore');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Lấy danh sách FCM tokens của tất cả user
  Future<List<String>> getAllUserTokens() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String)
          .where((token) => token.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting user tokens: $e');
      return [];
    }
  }

  // Gửi notification đến tất cả users
  Future<bool> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Trong trường hợp này, sử dụng topic sẽ hiệu quả hơn
    return await sendNotificationToTopic(
      topic: 'all_users',
      title: title,
      body: body,
      data: data,
    );
  }
}
