import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';

class RecipeManagementScreen extends StatefulWidget {
  const RecipeManagementScreen({Key? key}) : super(key: key);

  @override
  State<RecipeManagementScreen> createState() => _RecipeManagementScreenState();
}

class _RecipeManagementScreenState extends State<RecipeManagementScreen> {
  final FirestoreService _service = FirestoreService();

  void _deleteRecipe(String recipeId) async {
    await _service.deleteRecipe(recipeId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý công thức')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final recipes = snapshot.data!.docs
              .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          if (recipes.isEmpty) {
            return const Center(child: Text('Không có công thức nào.'));
          }
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                leading: const Icon(Icons.book),
                title: Text(recipe.title),
                subtitle: Text(
                  'Tác giả: ${recipe.createdBy}\nDanh mục: ${recipe.category}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRecipe(recipe.id),
                ),
                onTap: () {
                  // Optionally: show detail or edit
                },
              );
            },
          );
        },
      ),
    );
  }
}