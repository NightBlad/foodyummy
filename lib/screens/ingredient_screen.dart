import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientScreen extends StatefulWidget {
  const IngredientScreen({Key? key}) : super(key: key);

  @override
  State<IngredientScreen> createState() => _IngredientScreenState();
}

class _IngredientScreenState extends State<IngredientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String searchQuery = '';

  List<Ingredient> _ingredients = [
    Ingredient(id: '1', name: 'Tomato', type: 'Vegetable'),
    Ingredient(id: '2', name: 'Chicken', type: 'Meat'),
    Ingredient(id: '3', name: 'Salt', type: 'Spice'),
  ];

  void _addIngredient() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() {
      _ingredients.add(Ingredient(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
      ));
      _nameController.clear();
      _typeController.clear();
    });
  }

  void _editIngredient(Ingredient ingredient) {
    _nameController.text = ingredient.name;
    _typeController.text = ingredient.type;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              setState(() {
                final index = _ingredients.indexWhere((ing) => ing.id == ingredient.id);
                if (index != -1) {
                  _ingredients[index] = Ingredient(
                    id: ingredient.id,
                    name: _nameController.text.trim(),
                    type: _typeController.text.trim(),
                  );
                }
              });
              _nameController.clear();
              _typeController.clear();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              _nameController.clear();
              _typeController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteIngredient(String id) {
    setState(() {
      _ingredients.removeWhere((ing) => ing.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredIngredients = _ingredients.where((ing) =>
      ing.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      ing.type.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addIngredient,
                  child: const Icon(Icons.add),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredIngredients.isEmpty
                  ? Center(child: Text('No ingredients found'))
                  : ListView.builder(
                      itemCount: filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = filteredIngredients[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ingredient.type),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  onPressed: () => _editIngredient(ingredient),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteIngredient(ingredient.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
