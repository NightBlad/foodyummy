import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Trang Chủ Demo Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    IngredientScreen(),
    MenuScreen(),
    FavoriteScreen(),
    SearchScreen(),
    NotificationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Nguyên Liệu'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Thực Đơn'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu Thích'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm Kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông Báo'),
        ],
      ),
    );
  }
}

// Placeholder screens for navigation
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Chào mừng đến với Foodyummy!', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 16),
          Text('Quản lý nguyên liệu, thực đơn, món yêu thích và hơn thế nữa.', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class IngredientScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Quản Lý Nguyên Liệu'));
  }
}

class FavoriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Món Yêu Thích'));
  }
}

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Tìm Kiếm'));
  }
}

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Thông Báo'));
  }
}