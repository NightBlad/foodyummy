import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/firestore_service.dart';

class IngredientManagementScreen extends StatefulWidget {
  const IngredientManagementScreen({Key? key}) : super(key: key);

  @override
  State<IngredientManagementScreen> createState() =>
      _IngredientManagementScreenState();
}

class _IngredientManagementScreenState
    extends State<IngredientManagementScreen> {
  final FirestoreService _service = FirestoreService();
  final TextEditingController _nameController = TextEditingController();

  void _addIngredient() async {
    if (_nameController.text.trim().isEmpty) return;
    await _service.addIngredient(
      Ingredient(
        id: '',
        name: _nameController.text.trim(),
        type: '', // or provide a type if you want
      ),
    );
    _nameController.clear();
    setState(() {});
  }

  void _deleteIngredient(String id) async {
    await _service.deleteIngredient(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nguyên liệu')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nguyên liệu',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addIngredient,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ingredients')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final ingredients = snapshot.data!.docs
                    .map(
                      (doc) => Ingredient.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                    .toList();
                if (ingredients.isEmpty) {
                  return const Center(child: Text('Không có nguyên liệu nào.'));
                }
                return ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = ingredients[index];
                    return ListTile(
                      leading: const Icon(Icons.kitchen),
                      title: Text(ingredient.name),
                      subtitle: Text(ingredient.type),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteIngredient(ingredient.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}