import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({Key? key}) : super(key: key);

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  String searchQuery = '';

  Future<void> addRecipe() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm món ăn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên món')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('recipes').add({
                'name': nameController.text,
                'description': descController.text,
                'createdBy': FirebaseAuth.instance.currentUser?.uid,
              });
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> updateRecipe(String id, String oldName, String oldDesc) async {
    final nameController = TextEditingController(text: oldName);
    final descController = TextEditingController(text: oldDesc);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa món ăn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên món')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('recipes').doc(id).update({
                'name': nameController.text,
                'description': descController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteRecipe(String id) async {
    await FirebaseFirestore.instance.collection('recipes').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final recipesQuery = FirebaseFirestore.instance
        .collection('recipes')
        .where('name', isGreaterThanOrEqualTo: searchQuery)
        .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý món ăn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addRecipe,
            tooltip: 'Thêm món ăn',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Đăng xuất',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: searchQuery.isEmpty
            ? FirebaseFirestore.instance.collection('recipes').snapshots()
            : recipesQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Không có món ăn nào.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['description'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => updateRecipe(doc.id, data['name'] ?? '', data['description'] ?? ''),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteRecipe(doc.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 