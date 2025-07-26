import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt hệ thống')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Bật chế độ bảo trì (Maintenance Mode)'),
            value: maintenanceMode,
            onChanged: (val) {
              setState(() {
                maintenanceMode = val;
              });
            },
            secondary: const Icon(Icons.build),
          ),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Thông tin ứng dụng'),
            subtitle: Text('FoodyYummy Admin Panel v1.0'),
          ),
        ],
      ),
    );
  }
}