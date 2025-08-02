import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AutoNotificationService {
  static final AutoNotificationService _instance = AutoNotificationService._internal();
  factory AutoNotificationService() => _instance;
  AutoNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Tạo notification trigger trong Firestore khi thêm recipe
  Future<bool> createNotificationTrigger({
    required String recipeId,
    required String recipeTitle,
    required String authorId,
    String? category,
  }) async {
    try {
      // Tạo document trong collection notification_triggers
      await _firestore.collection('notification_triggers').add({
        'type': 'new_recipe',
        'recipe_id': recipeId,
        'recipe_title': recipeTitle,
        'recipe_category': category,
        'author_id': authorId,
        'created_at': FieldValue.serverTimestamp(),
        'processed': false,
        'notification_data': {
          'title': '🍽️ Món mới đã có!',
          'body': 'Khám phá ngay công thức "$recipeTitle"${category != null ? ' thuộc danh mục $category' : ''}',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'recipe_id': recipeId,
          'recipe_title': recipeTitle,
        }
      });

      if (kDebugMode) {
        print('Notification trigger created for recipe: $recipeTitle');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification trigger: $e');
      }
      return false;
    }
  }

  // Gửi thông báo qua FCM Legacy API (đơn giản hơn)
  Future<bool> sendLegacyFCMNotification({
    required String title,
    required String body,
    required String topic,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Sử dụng legacy server key thực từ Firebase Console
      const String serverKey = 'BPlf2vZubvhkDDbm45_P9W6nf6QykoQzemNDNMLOPrjvD_xnij6uFOkXQLM_HuHHdAcdIsadQWbtDajbt1HGUl4'; // Cần thay bằng server key thực từ Firebase

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: json.encode({
          'to': '/topics/$topic',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': '1',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'data': data ?? {},
          'priority': 'high',
          'content_available': true,
          'android': {
            'notification': {
              'channel_id': 'foodyummy_channel',
              'priority': 'max',
              'default_sound': true,
              'default_vibrate': true,
            }
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
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Legacy FCM notification sent successfully to topic: $topic');
          print('📱 Response: ${response.body}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to send legacy FCM notification: ${response.statusCode}');
          print('📱 Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error sending legacy FCM notification: $e');
      }
      return false;
    }
  }

  // Listen cho notification triggers và tự động gửi
  void startListening() {
    _firestore
        .collection('notification_triggers')
        .where('processed', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _processNotificationTrigger(change.doc);
        }
      }
    });

    if (kDebugMode) {
      print('Auto notification service started listening...');
    }
  }

  // Xử lý notification trigger
  Future<void> _processNotificationTrigger(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final notificationData = data['notification_data'] as Map<String, dynamic>;

      // Gửi notification
      bool success = await sendLegacyFCMNotification(
        title: notificationData['title'],
        body: notificationData['body'],
        topic: 'new_recipes',
        data: {
          'type': 'new_recipe',
          'recipe_id': notificationData['recipe_id'],
          'recipe_title': notificationData['recipe_title'],
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );

      // Đánh dấu đã xử lý
      await doc.reference.update({
        'processed': true,
        'processed_at': FieldValue.serverTimestamp(),
        'success': success,
      });

      if (kDebugMode) {
        print('Processed notification trigger: ${data['recipe_title']} - Success: $success');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing notification trigger: $e');
      }
    }
  }

  // Subscribe user tự động khi mở app
  Future<void> ensureTopicSubscription() async {
    try {
      await _messaging.subscribeToTopic('new_recipes');
      await _messaging.subscribeToTopic('all_users');

      if (kDebugMode) {
        print('Ensured topic subscription');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ensuring topic subscription: $e');
      }
    }
  }

  // Cleanup old processed triggers (chạy định kỳ)
  Future<void> cleanupOldTriggers() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));

      final query = await _firestore
          .collection('notification_triggers')
          .where('processed', isEqualTo: true)
          .where('processed_at', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print('Cleaned up ${query.docs.length} old notification triggers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old triggers: $e');
      }
    }
  }
}
