import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import 'menu_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      print('🔔 Đang khởi tạo notification service...');

      // Khởi tạo NotificationService
      await NotificationService().initialize();

      // Subscribe to topics cho user này
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Subscribe to general topics
        await NotificationService().subscribeToTopic('all_users');
        await NotificationService().subscribeToTopic('recipes_updates');

        // Subscribe to user-specific topic
        await NotificationService().subscribeToTopic('user_${user.uid}');

        print('✅ Notifications initialized successfully');
        print('📱 FCM Token: ${await NotificationService().getToken()}');
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      // Vẫn cho phép app chạy dù notification có lỗi
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
              ),
              SizedBox(height: 16),
              Text(
                'Đang thiết lập thông báo...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const RecipeScreen();
  }
}
