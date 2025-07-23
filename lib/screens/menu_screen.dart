import 'package:flutter/material.dart';

class Menu {
  final String id;
  final String name;
  final String type;
  final List<Recipe> recipes;
  Menu({required this.id, required this.name, required this.type, required this.recipes});
}

class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final String instructions;
  Recipe({required this.id, required this.name, required this.ingredients, required this.instructions});
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Menu> _menus = [
    Menu(
      id: '1',
      name: 'Lunch Set',
      type: 'Lunch',
      recipes: [
        Recipe(
          id: 'r1',
          name: 'Fried Rice',
          ingredients: ['Rice', 'Egg', 'Carrot', 'Peas'],
          instructions: 'Stir fry all ingredients together.',
        ),
        Recipe(
          id: 'r2',
          name: 'Tomato Soup',
          ingredients: ['Tomato', 'Water', 'Salt'],
          instructions: 'Boil tomatoes, add salt.',
        ),
      ],
    ),
    Menu(
      id: '2',
      name: 'Dinner Set',
      type: 'Dinner',
      recipes: [
        Recipe(
          id: 'r3',
          name: 'Grilled Chicken',
          ingredients: ['Chicken', 'Salt', 'Pepper'],
          instructions: 'Grill chicken with salt and pepper.',
        ),
      ],
    ),
  ];

  final TextEditingController _menuNameController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';
  final List<String> _mealTypes = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Vegetarian', 'Vegan', 'Vietnamese', 'Western'];

  void _addMenu() {
    String _newType = 'Lunch';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _menuNameController,
              decoration: const InputDecoration(labelText: 'Menu Name'),
            ),
            DropdownButtonFormField<String>(
              value: _newType,
              items: _mealTypes.where((e) => e != 'All').map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) {
                if (val != null) _newType = val;
              },
              decoration: const InputDecoration(labelText: 'Meal Type'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_menuNameController.text.trim().isNotEmpty) {
                setState(() {
                  _menus.add(Menu(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _menuNameController.text.trim(),
                    type: _newType,
                    recipes: [],
                  ));
                });
              }
              _menuNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () {
              _menuNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _editMenu(Menu menu) {
    _menuNameController.text = menu.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Menu'),
        content: TextField(
          controller: _menuNameController,
          decoration: const InputDecoration(labelText: 'Menu Name'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                final index = _menus.indexWhere((m) => m.id == menu.id);
                if (index != -1) {
                  _menus[index] = Menu(
                    id: menu.id,
                    name: _menuNameController.text.trim(),
                    type: menu.type,
                    recipes: menu.recipes,
                  );
                }
              });
              _menuNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              _menuNameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteMenu(String id) {
    setState(() {
      _menus.removeWhere((m) => m.id == id);
    });
  }

  void _showRecipes(Menu menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(menu.name, style: Theme.of(context).textTheme.headlineSmall),
            ...menu.recipes.map((recipe) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingredients: ${recipe.ingredients.join(", ")}'),
                    Text('Instructions: ${recipe.instructions}'),
                  ],
                ),
              ),
            )),
            if (menu.recipes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No recipes in this menu.'),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Recipe'),
              onPressed: () => _addRecipe(menu),
            ),
          ],
        ),
      ),
    );
  }

  final TextEditingController _recipeNameController = TextEditingController();
  final TextEditingController _recipeIngredientsController = TextEditingController();
  final TextEditingController _recipeInstructionsController = TextEditingController();

  void _addRecipe(Menu menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Recipe'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _recipeNameController,
                decoration: const InputDecoration(labelText: 'Recipe Name'),
              ),
              TextField(
                controller: _recipeIngredientsController,
                decoration: const InputDecoration(labelText: 'Ingredients (comma separated)'),
              ),
              TextField(
                controller: _recipeInstructionsController,
                decoration: const InputDecoration(labelText: 'Instructions'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_recipeNameController.text.trim().isNotEmpty) {
                setState(() {
                  menu.recipes.add(Recipe(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _recipeNameController.text.trim(),
                    ingredients: _recipeIngredientsController.text.split(',').map((e) => e.trim()).toList(),
                    instructions: _recipeInstructionsController.text.trim(),
                  ));
                });
              }
              _recipeNameController.clear();
              _recipeIngredientsController.clear();
              _recipeInstructionsController.clear();
              Navigator.pop(context);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              _showRecipes(menu);
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () {
              _recipeNameController.clear();
              _recipeIngredientsController.clear();
              _recipeInstructionsController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Menu> filteredMenus = _menus.where((menu) {
      final matchesType = _selectedType == 'All' || menu.type == _selectedType;
      final matchesSearch = menu.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();
    filteredMenus.sort((a, b) => a.type.compareTo(b.type));
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Foodyummy Menus', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8BBD0), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Danh sách thực đơn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm thực đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addMenu,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Tìm kiếm thực đơn...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedType,
                        items: _mealTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() { _selectedType = val; });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredMenus.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book, size: 64, color: Colors.deepPurple.shade200),
                          const SizedBox(height: 16),
                          const Text('Không có thực đơn nào', style: TextStyle(fontSize: 18, color: Colors.deepPurple)),
                        ],
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredMenus.length,
                        itemBuilder: (context, index) {
                          final menu = filteredMenus[index];
                          return GestureDetector(
                            onTap: () => _showRecipes(menu),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.deepPurple),
                                      onSelected: (value) {
                                        if (value == 'edit') _editMenu(menu);
                                        if (value == 'delete') _deleteMenu(menu.id);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                        const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                      ],
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.restaurant_menu, size: 40, color: Colors.deepPurple),
                                        const SizedBox(height: 8),
                                        Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(menu.type, style: const TextStyle(color: Colors.deepPurple)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${menu.recipes.length} món ăn', style: const TextStyle(color: Colors.pinkAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Text('💡 Mẹo: Nhấn vào thực đơn để xem và thêm món ăn!', style: TextStyle(color: Colors.deepPurple.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}
