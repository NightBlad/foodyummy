import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../services/gemini_service.dart';
import '../services/recipe_service.dart';
import '../services/auth_service.dart';
import '../services/usage_limit_service.dart';

class AIRecipeGeneratorScreen extends StatefulWidget {
  const AIRecipeGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<AIRecipeGeneratorScreen> createState() =>
      _AIRecipeGeneratorScreenState();
}

class _AIRecipeGeneratorScreenState extends State<AIRecipeGeneratorScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final List<String> _ingredients = [];
  bool _isGenerating = false;
  Recipe? _generatedRecipe;
  final _uuid = const Uuid();

  // Thêm biến để theo dõi usage
  Map<String, int> _currentUsage = {'used': 0, 'limit': 0};
  bool _canGenerate = true;

  @override
  void initState() {
    super.initState();
    _checkUsageLimit();
  }

  // Kiểm tra giới hạn sử dụng
  Future<void> _checkUsageLimit() async {
    try {
      final canGenerate = await UsageLimitService.canGenerateRecipe();
      final usage = await UsageLimitService.getCurrentUsage();

      setState(() {
        _canGenerate = canGenerate;
        _currentUsage = usage;
      });
    } catch (e) {
      print('Error checking usage limit: $e');
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _generateRecipe() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một nguyên liệu')),
      );
      return;
    }

    // Kiểm tra giới hạn sử dụng trước khi tạo
    if (!_canGenerate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn đã đạt giới hạn tạo công thức AI hôm nay (${_currentUsage['used']}/${_currentUsage['limit']}). Vui lòng thử lại vào ngày mai.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedRecipe = null;
    });

    try {
      final recipeData = await GeminiService.generateRecipeFromIngredients(
        ingredients: _ingredients,
        additionalRequirements: _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
      );

      if (recipeData != null) {
        // Ghi nhận việc sử dụng AI
        await UsageLimitService.recordAIRecipeUsage();

        // Cập nhật usage counter
        await _checkUsageLimit();

        final currentUser = AuthService.currentUser;
        final recipe = Recipe(
          id: _uuid.v4(),
          title: recipeData['title'],
          description: recipeData['description'],
          images: [], // Sẽ được cập nhật sau khi người dùng thêm ảnh
          ingredients: recipeData['ingredients'],
          instructions: recipeData['instructions'],
          category: recipeData['category'],
          cookingTime: recipeData['cookingTime'],
          servings: recipeData['servings'],
          difficulty: recipeData['difficulty'],
          createdBy: currentUser?.id ?? 'anonymous',
          createdAt: DateTime.now(),
          tags: recipeData['tags'],
        );

        setState(() {
          _generatedRecipe = recipe;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo công thức thành công! Còn lại: ${_currentUsage['limit']! - _currentUsage['used']! - 1}/${_currentUsage['limit']} lần sử dụng hôm nay.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo công thức. Vui lòng thử lại.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (_generatedRecipe == null) return;

    try {
      await RecipeService.addRecipe(_generatedRecipe!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Công thức đã được lưu thành công!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu công thức: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Công Thức AI'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUsageLimitCard(),
            const SizedBox(height: 20),
            _buildIngredientsSection(),
            const SizedBox(height: 20),
            _buildRequirementsSection(),
            const SizedBox(height: 20),
            _buildGenerateButton(),
            if (_generatedRecipe != null) ...[
              const SizedBox(height: 30),
              _buildGeneratedRecipe(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageLimitCard() {
    return Card(
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giới hạn sử dụng công thức AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn còn ${_currentUsage['limit']! - _currentUsage['used']!} lần sử dụng hôm nay.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 8),
                  if (!_canGenerate) ...[
                    Text(
                      'Bạn đã đạt giới hạn sử dụng hôm nay.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vui lòng thử lại vào ngày mai.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nguyên liệu có sẵn',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập nguyên liệu...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addIngredient,
                  child: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ingredients.isNotEmpty) ...[
              Text(
                'Nguyên liệu đã thêm:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ingredient = entry.value;
                  return Chip(
                    label: Text(ingredient),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeIngredient(index),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yêu cầu thêm (không bắt buộc)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _requirementsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Món chay, không cay, dành cho trẻ em...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _isGenerating || !_canGenerate ? null : _generateRecipe,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isGenerating
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text('Đang tạo công thức...'),
              ],
            )
          : const Text('Tạo Công Thức AI'),
    );
  }

  Widget _buildGeneratedRecipe() {
    if (_generatedRecipe == null) return const SizedBox.shrink();

    final recipe = _generatedRecipe!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Công thức được tạo',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saveRecipe,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecipeDetails(recipe),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDetails(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(recipe.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.timer, '${recipe.cookingTime} phút'),
            _buildInfoChip(Icons.people, '${recipe.servings} người'),
            _buildInfoChip(Icons.signal_cellular_alt, recipe.difficulty),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Nguyên liệu:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...recipe.ingredients.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, size: 8),
                const SizedBox(width: 8),
                Expanded(child: Text(ingredient)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cách thực hiện:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...recipe.instructions.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(instruction)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
    );
  }
}
