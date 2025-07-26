                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'Tên Thực Đơn'),
                              ),
                              TextField(
                                controller: _categoryController,
                                decoration: const InputDecoration(labelText: 'Danh Mục'),
                              ),
                              TextField(
                                controller: _priceController,
                                decoration: const InputDecoration(labelText: 'Giá'),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(labelText: 'Mô Tả'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                if (_nameController.text.trim().isNotEmpty) {
                                  addFood();
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Thêm'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Hủy'),
                            ),
                          ],
                        ),
                      );
                    },
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class MenuScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> addFood() async {
    String name = _nameController.text;
    String category = _categoryController.text;
    double price = double.parse(_priceController.text);
    String description = _descriptionController.text;
    String createdBy = FirebaseAuth.instance.currentUser!.uid;

    await _firestoreService.addFoodItem(name, category, price, description, createdBy);
  }

  const MenuScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Thực Đơn Foodyummy', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: Text('Danh Sách Thực Đơn', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Thực Đơn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Thêm Thực Đơn'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
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