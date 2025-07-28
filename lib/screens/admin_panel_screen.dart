
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Quản lý người dùng'),
            onTap: () {
              Navigator.pushNamed(context, '/user-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Quản lý công thức'),
            onTap: () {
              Navigator.pushNamed(context, '/recipe-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.kitchen),
            title: const Text('Quản lý nguyên liệu'),
            onTap: () {
              Navigator.pushNamed(context, '/ingredient-management');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Thống kê & Báo cáo'),
            onTap: () {
              Navigator.pushNamed(context, '/admin-statistics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài đặt hệ thống'),
            onTap: () {
              Navigator.pushNamed(context, '/admin-settings');
            },
          ),
        ],
      ),
    );
  }
}
