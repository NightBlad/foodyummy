import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({Key? key}) : super(key: key);

  Future<Map<String, int>> _fetchStats() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    final recipes = await FirebaseFirestore.instance
        .collection('recipes')
        .get();
    final ingredients = await FirebaseFirestore.instance
        .collection('ingredients')
        .get();
    return {
      'users': users.size,
      'recipes': recipes.size,
      'ingredients': ingredients.size,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê & Báo cáo')),
      body: FutureBuilder<Map<String, int>>(
        future: _fetchStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.people),
                title: Text('Tổng số người dùng: ${stats['users']}'),
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: Text('Tổng số công thức: ${stats['recipes']}'),
              ),
              ListTile(
                leading: const Icon(Icons.kitchen),
                title: Text('Tổng số nguyên liệu: ${stats['ingredients']}'),
              ),
            ],
          );
        },
      ),
    );
  }
}