import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../services/firestore_service.dart';

class IngredientScreen extends StatefulWidget {
  final String userId;
  const IngredientScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String searchQuery = '';

  void _addIngredient() async {
    if (_nameController.text.trim().isEmpty) return;
    final service = Provider.of<FirestoreService>(context, listen: false);
    await service.addIngredient(
      widget.userId,
      Ingredient(id: '', name: _nameController.text.trim(), type: _typeController.text.trim()),
    );
    _nameController.clear();
    _typeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredients'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ingredient Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addIngredient,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Ingredient>>(
              stream: searchQuery.isEmpty
                  ? service.getIngredients(widget.userId)
                  : service.searchIngredients(widget.userId, searchQuery),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final ingredients = snapshot.data!;
                return ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = ingredients[index];
                    return ListTile(
                      title: Text(ingredient.name),
                      subtitle: Text(ingredient.type),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              _nameController.text = ingredient.name;
                              _typeController.text = ingredient.type;
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Edit Ingredient'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(labelText: 'Ingredient Name'),
                                        ),
                                        TextField(
                                          controller: _typeController,
                                          decoration: const InputDecoration(labelText: 'Type'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          if (_nameController.text.trim().isEmpty) return;
                                          await service.updateIngredient(
                                            ingredient.id,
                                            Ingredient(id: ingredient.id, name: _nameController.text.trim(), type: _typeController.text.trim()),
                                          );
                                          _nameController.clear();
                                          _typeController.clear();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Save'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _nameController.clear();
                                          _typeController.clear();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await service.deleteIngredient(ingredient.id);
                            },
                          ),
                        ],
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
