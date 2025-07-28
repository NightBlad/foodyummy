import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  String? _currentUserRole;
  String? _fcmToken;
  String _selectedMode = 'token'; // 'token' or 'topic'

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserData();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    String? token = await _notificationService.getToken();
    setState(() {
      _fcmToken = token;
      _tokenController.text = token ?? '';
    });
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userData = await _firestoreService.getUser(currentUser.uid); // Sửa từ getUserById thành getUser
        if (userData != null && mounted) {
          setState(() {
            _currentUserRole = userData.role;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải thông tin người dùng: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung')),
      );
      return;
    }

    if (_selectedMode == 'token' && _tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập FCM Token')),
      );
      return;
    }

    if (_selectedMode == 'topic' && _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Topic')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_selectedMode == 'token') {
        success = await _notificationService.sendNotificationToUser(
          title: _titleController.text,
          body: _bodyController.text,
          userToken: _tokenController.text,
          data: {
            'type': 'test',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        success = await _notificationService.sendNotification(
          title: _titleController.text,
          body: _bodyController.text,
          topic: _topicController.text,
          data: {
            'type': 'test',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
              ? 'Gửi thông báo thành công!'
              : 'Gửi thông báo thất bại!'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendToAllUsers() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _notificationService.sendNotificationToAll(
        title: _titleController.text,
        body: _bodyController.text,
        data: {
          'type': 'broadcast',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
              ? 'Gửi thông báo đến tất cả người dùng thành công!'
              : 'Gửi thông báo thất bại!'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _subscribeToTopic() async {
    if (_topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên topic')),
      );
      return;
    }

    try {
      await _notificationService.subscribeToTopic(_topicController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đăng ký topic: ${_topicController.text}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng ký topic: $e')),
        );
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      String? token = await _notificationService.getToken();
      setState(() {
        _fcmToken = token;
        _tokenController.text = token ?? '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã làm mới FCM Token')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi làm mới token: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tokenController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Thông Báo'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FCM Token hiện tại
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'FCM Token hiện tại:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshToken,
                          tooltip: 'Làm mới token',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _fcmToken ?? 'Chưa có token',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chế độ gửi thông báo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chế độ gửi thông báo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'token',
                          groupValue: _selectedMode,
                          onChanged: (value) {
                            setState(() {
                              _selectedMode = value!;
                            });
                          },
                        ),
                        const Text('Gửi theo Token'),
                        Radio<String>(
                          value: 'topic',
                          groupValue: _selectedMode,
                          onChanged: (value) {
                            setState(() {
                              _selectedMode = value!;
                            });
                          },
                        ),
                        const Text('Gửi theo Topic'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Form nhập liệu
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề thông báo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Nội dung thông báo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Token hoặc Topic input
            if (_selectedMode == 'token')
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'FCM Token đích',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.token),
                  helperText: 'Token của thiết bị nhận thông báo',
                ),
              ),

            if (_selectedMode == 'topic')
              Column(
                children: [
                  TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.topic),
                      helperText: 'Tên topic để gửi thông báo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _subscribeToTopic,
                    icon: const Icon(Icons.add),
                    label: const Text('Đăng ký Topic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Buttons
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                  label: Text(_selectedMode == 'token'
                    ? 'Gửi thông báo theo Token'
                    : 'Gửi thông báo theo Topic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),

                const SizedBox(height: 12),

                if (_currentUserRole == 'admin')
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendToAllUsers,
                    icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.broadcast_on_personal),
                    label: const Text('Gửi đến tất cả người dùng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Hướng dẫn
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hướng dẫn sử dụng:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Chọn chế độ gửi: Token (gửi đến thiết bị cụ thể) hoặc Topic (gửi đến nhóm)'),
                    const Text('2. Nhập tiêu đề và nội dung thông báo'),
                    const Text('3. Nếu gửi theo Token: sao chép token từ trên xuống hoặc nhập token khác'),
                    const Text('4. Nếu gửi theo Topic: nhập tên topic và đăng ký trước khi gửi'),
                    const Text('5. Nhấn nút gửi để test thông báo'),
                    const SizedBox(height: 8),
                    const Text(
                      'Lưu ý: Ứng dụng đã sử dụng Firebase HTTP v1 API mới thay thế Legacy API đã bị Google ngừng hỗ trợ.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
