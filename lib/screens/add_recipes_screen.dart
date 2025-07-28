import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/hybrid_image_widget.dart';
import '../widgets/image_gallery_widget.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddRecipeScreen({super.key, this.recipe});

  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  // Hỗ trợ tối đa 5 ảnh
  List<File> _selectedImages = [];
  List<String> _currentImageUrls = [];

  List<TextEditingController> _ingredientControllers = [TextEditingController()];
  List<TextEditingController> _instructionControllers = [TextEditingController()];
  List<String> _tags = [];

  String _selectedCategory = 'Món chính';
  String _selectedDifficulty = 'easy';
  bool _isLoading = false;

  final List<String> _categories = [
    'Món chính',
    'Món phụ',
    'Tráng miệng',
    'Đồ uống',
    'Món ăn sáng',
    'Món ăn nhẹ',
    'Súp',
  ];

  final List<String> _difficulties = ['easy', 'medium', 'hard'];
  final Map<String, String> _difficultyLabels = {
    'easy': 'Dễ',
    'medium': 'Trung bình',
    'hard': 'Khó',
  };

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _loadRecipeData();
    }
  }

  void _loadRecipeData() {
    final recipe = widget.recipe!;
    _titleController.text = recipe.title;
    _descriptionController.text = recipe.description;
    _currentImageUrls = List.from(recipe.images);
    _cookingTimeController.text = recipe.cookingTime.toString();
    _servingsController.text = recipe.servings.toString();
    _selectedCategory = recipe.category;
    _selectedDifficulty = recipe.difficulty;
    _tags = List.from(recipe.tags);

    _ingredientControllers = recipe.ingredients
        .map((ingredient) => TextEditingController(text: ingredient))
        .toList();
    if (_ingredientControllers.isEmpty) {
      _ingredientControllers.add(TextEditingController());
    }

    _instructionControllers = recipe.instructions
        .map((instruction) => TextEditingController(text: instruction))
        .toList();
    if (_instructionControllers.isEmpty) {
      _instructionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();

    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _instructionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles
            .take(5)
            .map((file) => File(file.path))
            .toList();
        _currentImageUrls = [];
      });

      if (pickedFiles.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ có thể chọn tối đa 5 ảnh. Ảnh đầu tiên sẽ là ảnh bìa.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chọn ảnh thành công! Ảnh đầu tiên sẽ là ảnh bìa.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeCurrentImage(int index) {
    setState(() {
      _currentImageUrls.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      if (_selectedImages.isNotEmpty) {
        final item = _selectedImages.removeAt(oldIndex);
        _selectedImages.insert(newIndex, item);
      } else {
        final item = _currentImageUrls.removeAt(oldIndex);
        _currentImageUrls.insert(newIndex, item);
      }
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.recipe == null &&
        _selectedImages.isEmpty &&
        _currentImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ảnh cho món ăn'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ingredients = _ingredientControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final instructions = _instructionControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      List<String> imageUrls = List.from(_currentImageUrls);

      if (_selectedImages.isNotEmpty) {
        imageUrls = [];
        for (int i = 0; i < _selectedImages.length; i++) {
          String url = await _cloudinaryService.uploadImage(_selectedImages[i]);
          imageUrls.add(url);
        }
      }

      final recipe = Recipe(
        id: widget.recipe?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: imageUrls,
        ingredients: ingredients,
        instructions: instructions,
        category: _selectedCategory,
        cookingTime: int.parse(_cookingTimeController.text),
        servings: int.parse(_servingsController.text),
        difficulty: _selectedDifficulty,
        createdBy: user.uid,
        createdAt: widget.recipe?.createdAt ?? DateTime.now(),
        tags: _tags,
        rating: widget.recipe?.rating ?? 0.0,
        ratingCount: widget.recipe?.ratingCount ?? 0,
      );

      if (widget.recipe == null) {
        await _firestoreService.addRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm công thức thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _firestoreService.updateRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật công thức thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Thêm công thức' : 'Chỉnh sửa công thức'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin cơ bản
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin cơ bản',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên món ăn',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên món ăn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phần chọn ảnh
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_library, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hình ảnh món ăn',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'Tối đa 5 ảnh',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Ảnh đầu tiên sẽ là ảnh bìa\n• Lướt để xem tất cả ảnh\n• Chạm vào nút xóa để xóa ảnh',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      // Sử dụng ImageGalleryWidget mới
                      ImageGalleryWidget(
                        imageFiles: _selectedImages,
                        imageUrls: _currentImageUrls,
                        isEditable: true,
                        onRemove: (index) {
                          // Xử lý xóa ảnh
                          if (_selectedImages.isNotEmpty) {
                            _removeSelectedImage(index);
                          } else {
                            _removeCurrentImage(index);
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_selectedImages.length < 5 && _currentImageUrls.length < 5)
                              ? _pickImages
                              : null,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(
                            _selectedImages.isEmpty && _currentImageUrls.isEmpty
                                ? 'Chọn ảnh món ăn'
                                : 'Thay đổi ảnh',
                          ),
                        ),
                      ),
                      if (_selectedImages.length >= 5 || _currentImageUrls.length >= 5)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Đã đạt giới hạn tối đa 5 ảnh',
                                style: TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nguyên liệu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyên liệu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._ingredientControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        TextEditingController controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Nguyên liệu ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (index == 0 && (value == null || value.trim().isEmpty)) {
                                      return 'Vui lòng nhập ít nhất 1 nguyên liệu';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_ingredientControllers.length > 1)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _ingredientControllers.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                ),
                            ],
                          ),
                        );
                      }),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _ingredientControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm nguyên liệu'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cách làm
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cách làm',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._instructionControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        TextEditingController controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: 'Bước ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (index == 0 && (value == null || value.trim().isEmpty)) {
                                      return 'Vui lòng nhập ít nhất 1 bước làm';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_instructionControllers.length > 1)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _instructionControllers.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                ),
                            ],
                          ),
                        );
                      }),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _instructionControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm bước'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Thông tin bổ sung
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin bổ sung',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cookingTimeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Thời gian (phút)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập thời gian';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Vui lòng nhập số';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _servingsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số người ăn',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số người ăn';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Vui lòng nhập số';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        decoration: const InputDecoration(
                          labelText: 'Độ khó',
                          border: OutlineInputBorder(),
                        ),
                        items: _difficulties.map((difficulty) {
                          return DropdownMenuItem(
                            value: difficulty,
                            child: Text(_difficultyLabels[difficulty]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _saveRecipe,
          backgroundColor: Theme.of(context).primaryColor,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(
            widget.recipe == null ? 'Thêm công thức' : 'Cập nhật công thức',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
