import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../services/local_image_service.dart';
import '../widgets/hybrid_image_widget.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe; // null = thêm mới, có giá trị = chỉnh sửa

  const AddRecipeScreen({super.key, this.recipe});

  @override
  _AddRecipeScreenState createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();

  // Image handling
  File? _selectedImage;
  String? _currentImageUrl;

  // Lists
  List<TextEditingController> _ingredientControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> _instructionControllers = [
    TextEditingController(),
  ];
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
    _currentImageUrl = recipe.imageUrl; // Load current image URL
    _cookingTimeController.text = recipe.cookingTime.toString();
    _servingsController.text = recipe.servings.toString();
    _selectedCategory = recipe.category;
    _selectedDifficulty = recipe.difficulty;
    _tags = List.from(recipe.tags);

    // Load ingredients
    _ingredientControllers = recipe.ingredients
        .map((ingredient) => TextEditingController(text: ingredient))
        .toList();
    if (_ingredientControllers.isEmpty) {
      _ingredientControllers.add(TextEditingController());
    }

    // Load instructions
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

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra xem có ảnh được chọn không (cho recipe mới)
    if (widget.recipe == null && _selectedImage == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh cho món ăn'),
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

      String imageUrl = _currentImageUrl ?? '';

      // Upload ảnh mới nếu có
      if (_selectedImage != null) {
        imageUrl = await LocalImageService.uploadImage(_selectedImage!);
      }

      final recipe = Recipe(
        id: widget.recipe?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
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
        // Thêm mới
        await _firestoreService.addRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm công thức thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context, true);
        }
      } else {
        // Cập nhật
        await _firestoreService.updateRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật công thức thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _currentImageUrl = null; // Clear current image URL
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[850]!] // Gradient tối cho dark mode
                : [Color(0xFFF8F9FA), Color(0xFFFFFFFF)], // Gradient sáng cho light mode
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, 'Thông tin cơ bản'),
                        _buildBasicInfoSection(context),
                        const SizedBox(height: 30),

                        _buildSectionTitle(context, 'Nguyên liệu'),
                        _buildIngredientsSection(context),
                        const SizedBox(height: 30),

                        _buildSectionTitle(context, 'Cách làm'),
                        _buildInstructionsSection(context),
                        const SizedBox(height: 30),

                        _buildSectionTitle(context, 'Thông tin bổ sung'),
                        _buildAdditionalInfoSection(context),
                        const SizedBox(
                          height: 100,
                        ), // Space for floating button
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSaveButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B6B)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.recipe == null
                  ? 'Thêm công thức mới'
                  : 'Chỉnh sửa công thức',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBasicInfoSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Tên món ăn',
            icon: Icons.restaurant_menu,
            validator: (value) =>
            value?.isEmpty == true ? 'Vui lòng nhập tên món ăn' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Mô tả',
            icon: Icons.description,
            maxLines: 3,
            validator: (value) =>
            value?.isEmpty == true ? 'Vui lòng nhập mô tả' : null,
          ),
          const SizedBox(height: 16),
          _buildImagePicker(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cookingTimeController,
                  label: 'Thời gian (phút)',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value?.isEmpty == true ? 'Nhập thời gian' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _servingsController,
                  label: 'Số người ăn',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value?.isEmpty == true ? 'Nhập số người' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _buildCategoryDropdown())]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: _buildDifficultyDropdown())]),
        ],
      ),
    );
  }


  Widget _buildImagePicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF6B6B),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _selectedImage != null
              ? Image.file(
            _selectedImage!,
            fit: BoxFit.cover,
            width: double.infinity,
          )
              : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
              ? HybridImageWidget(
            imagePath: _currentImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 150,
          )
              : _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt,
          color: const Color(0xFFFF6B6B),
          size: 40,
        ),
        const SizedBox(height: 8),
        Text(
          'Nhấn để chọn ảnh',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[200] : const Color(0xFFFF6B6B),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      enableIMEPersonalizedLearning: true,
      textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      autocorrect: true,
      enableSuggestions: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50], // Thay đổi fillColor
        hintText: _getHintText(label),
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w400,
          color: isDarkMode ? Colors.grey[200] : Colors.grey[700],
        ),
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontFamily: 'Roboto',
        ),
      ),
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  String _getHintText(String label) {
    switch (label) {
      case 'Tên món ăn':
        return 'Ví dụ: Phở bò, Bánh mì thịt...';
      case 'Mô tả':
        return 'Mô tả chi tiết về món ăn...';
      case 'Thời gian (phút)':
        return '30';
      case 'Số người ăn':
        return '4';
      default:
        return '';
    }
  }

  Widget _buildCategoryDropdown() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Danh mục',
        prefixIcon: const Icon(Icons.category, color: Color(0xFFFF6B6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[200] : Colors.grey[700],
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildDifficultyDropdown() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      decoration: InputDecoration(
        labelText: 'Độ khó',
        prefixIcon: const Icon(
          Icons.signal_cellular_alt,
          color: Color(0xFFFF6B6B),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[200] : Colors.grey[700],
        ),
      ),
      items: _difficulties.map((difficulty) {
        return DropdownMenuItem(
          value: difficulty,
          child: Text(
            _difficultyLabels[difficulty]!,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDifficulty = value!;
        });
      },
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ...List.generate(_ingredientControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientControllers[index],
                      enableIMEPersonalizedLearning: true,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nguyên liệu ${index + 1}',
                        hintText: 'Ví dụ: 500g thịt bò, 2 quả cà chua...',
                        prefixIcon: const Icon(
                          Icons.kitchen,
                          color: Color(0xFFFF6B6B),
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        filled: true,
                        fillColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (_ingredientControllers.length > 1) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _ingredientControllers[index].dispose();
                          _ingredientControllers.removeAt(index);
                        });
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _ingredientControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, color: Color(0xFFFF6B6B)),
              label: const Text(
                'Thêm nguyên liệu',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInstructionsSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ...List.generate(_instructionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instructionControllers[index],
                      maxLines: 3,
                      enableIMEPersonalizedLearning: true,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Bước ${index + 1}',
                        hintText: 'Ví dụ: Rửa sạch thịt, cắt thành miếng vừa ăn...',
                        prefixIcon: const Icon(
                          Icons.list_alt,
                          color: Color(0xFFFF6B6B),
                        ),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        filled: true,
                        fillColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  if (_instructionControllers.length > 1) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            _instructionControllers[index].dispose();
                            _instructionControllers.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _instructionControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, color: Color(0xFFFF6B6B)),
              label: const Text(
                'Thêm bước',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAdditionalInfoSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags (phân cách bằng dấu phẩy)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _tags.join(', '),
            onChanged: (value) {
              _tags = value
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
            },
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Ví dụ: nhanh, dễ làm, ít dầu mỡ',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              prefixIcon: const Icon(Icons.tag, color: Color(0xFFFF6B6B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSaveButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveRecipe,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B6B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 8,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.recipe == null ? Icons.add : Icons.save,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              widget.recipe == null
                  ? 'Thêm công thức'
                  : 'Cập nhật công thức',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}