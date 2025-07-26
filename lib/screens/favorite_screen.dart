import 'package:flutter/material.dart';
import '../models/favorite.dart';
import '../services/firestore_service.dart';

class FavoriteScreen extends StatefulWidget {
  final String userId;
  const FavoriteScreen({super.key, required this.userId});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  String searchQuery = '';
  String filterType = '';

  void _addFavorite() async {
    if (_nameController.text.trim().isEmpty) return;
    final service = FirestoreService();
    await service.addFavorite(
      Favorite(
        id: '',
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        userId: widget.userId,
      ),
    );
    _nameController.clear();
    _typeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    Stream<List<Favorite>> favoritesStream;
    if (searchQuery.isNotEmpty) {
      favoritesStream = service.searchFavorites(widget.userId, searchQuery);
    } else if (filterType.isNotEmpty) {
      favoritesStream = service.filterFavoritesByType(
        widget.userId,
        filterType,
      );
    } else {
      favoritesStream = service.getFavorites(widget.userId);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Món Yêu Thích')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên Món'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(labelText: 'Loại'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addFavorite,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Tìm Kiếm'),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: filterType.isEmpty ? null : filterType,
              hint: const Text('Lọc Theo Loại'),
              items:
              <String>[
                '',
                'Breakfast',
                'Vegetarian',
                'Vietnamese',
                'Western',
              ]
                  .map(
                    (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type.isEmpty ? 'Tất Cả' : type),
                ),
              )
                  .toList(),
              onChanged: (val) => setState(() => filterType = val ?? ''),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Favorite>>(
              stream: favoritesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final favorites = snapshot.data!;
                return ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = favorites[index];
                    return ListTile(
                      title: Text(favorite.name),
                      subtitle: Text(favorite.type),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              _nameController.text = favorite.name;
                              _typeController.text = favorite.type;
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Sửa Món Yêu Thích'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Tên Món',
                                          ),
                                        ),
                                        TextField(
                                          controller: _typeController,
                                          decoration: const InputDecoration(
                                            labelText: 'Loại',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          if (_nameController.text
                                              .trim()
                                              .isEmpty)
                                            return;
                                          await service.updateFavorite(
                                            favorite.id,
                                            Favorite(
                                              id: favorite.id,
                                              name: _nameController.text.trim(),
                                              type: _typeController.text.trim(),
                                              userId: widget.userId,
                                            ),
                                          );
                                          _nameController.clear();
                                          _typeController.clear();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Lưu'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _nameController.clear();
                                          _typeController.clear();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Hủy'),
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
                              await service.deleteFavorite(favorite.id);
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