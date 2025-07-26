import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hướng dẫn sử dụng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('- Đăng nhập để sử dụng đầy đủ chức năng.'),
            Text('- Thêm, tìm kiếm và lưu công thức nấu ăn.'),
            Text('- Chỉnh sửa thông tin cá nhân ở mục Cá nhân.'),
            Text('- Vào mục Cài đặt để thay đổi giao diện.'),
            SizedBox(height: 24),
            Text('Nếu cần hỗ trợ thêm, vui lòng liên hệ admin.'),
          ],
        ),
      ),
    );
  }
}