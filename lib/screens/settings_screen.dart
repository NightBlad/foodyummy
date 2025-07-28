import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings from local storage if needed
    // _loadSettings();
  }

  // Future<void> _loadSettings() async {
  //   // You can use SharedPreferences or similar for persistence
  //   // For demo, just keep default values
  //   // Example:
  //   // final prefs = await SharedPreferences.getInstance();
  //   // setState(() {
  //   //   _isDarkMode = prefs.getBool('darkMode') ?? false;
  //   //   _fontSize = prefs.getDouble('fontSize') ?? 16;
  //   // });
  // }

  // Future<void> _saveSettings() async {
  //   // Save settings to local storage
  //   // Example:
  //   // final prefs = await SharedPreferences.getInstance();
  //   // await prefs.setBool('darkMode', _isDarkMode);
  //   // await prefs.setDouble('fontSize', _fontSize);
  // }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            title: const Text('Chế độ nền tối'),
            trailing: Switch(
              value: appSettings.isDarkMode,
              onChanged: (value) => appSettings.setDarkMode(value),
            ),
          ),
          const SizedBox(height: 20),
          Text('Cỡ chữ', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 12,
            max: 28,
            divisions: 8,
            value: appSettings.fontSize,
            label: appSettings.fontSize.round().toString(),
            onChanged: (value) => appSettings.setFontSize(value),
          ),
          Text(
            'Xem trước cỡ chữ',
            style: TextStyle(fontSize: appSettings.fontSize),
          ),
        ],
      ),
    );
  }
}