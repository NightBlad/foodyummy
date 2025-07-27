import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import 'add_recipes_screen.dart';
import '../widgets/hybrid_image_widget.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  AppUser? _currentUser;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUser(user.uid);
      setState(() {
        _currentUser = userData;
        _isFavorite =
            userData?.favoriteRecipes.contains(widget.recipe.id) ?? false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.toggleFavoriteRecipe(
        _currentUser!.id,
        widget.recipe.id,
      );
      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecipe() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa công thức này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _firestoreService.deleteRecipe(widget.recipe.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa công thức thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecipeHeader(),
                _buildRecipeInfo(),
                _buildIngredients(),
                _buildInstructions(),
                const SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSliverAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFFF6B6B),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : const Color(0xFFFF6B6B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        if (_currentUser?.id == widget.recipe.createdBy || _currentUser?.isAdmin == true) ...[
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: isDarkMode ? Colors.white : const Color(0xFFFF6B6B),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: isDarkMode ? Colors.white : const Color(0xFFFF6B6B)),
                      const SizedBox(width: 8),
                      Text('Chỉnh sửa', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRecipeScreen(recipe: widget.recipe),
                        ),
                      );
                    });
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, _deleteRecipe);
                  },
                ),
              ],
            ),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.recipe.imageUrl.isNotEmpty
                ? HybridImageWidget(
              imageUrl: widget.recipe.imageUrl,
              fit: BoxFit.cover,
            )
                : Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.restaurant,
                size: 100,
                color: Colors.grey,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    isDarkMode
                        ? Colors.black.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecipeHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.recipe.category,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    widget.recipe.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    ' (${widget.recipe.ratingCount})',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.recipe.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.recipe.description,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRecipeInfo() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem(Icons.access_time, '${widget.recipe.cookingTime} phút', 'Thời gian', isDarkMode),
          _buildDivider(isDarkMode),
          _buildInfoItem(Icons.people, '${widget.recipe.servings} người', 'Khẩu phần', isDarkMode),
          _buildDivider(isDarkMode),
          _buildInfoItem(
            Icons.signal_cellular_alt,
            widget.recipe.difficulty == 'easy'
                ? 'Dễ'
                : widget.recipe.difficulty == 'medium'
                ? 'Trung bình'
                : 'Khó',
            'Độ khó',
            isDarkMode,
          ),
        ],
      ),
    );
  }



  Widget _buildInfoItem(IconData icon, String value, String label, bool isDarkMode) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF6B6B), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }


  Widget _buildDivider(bool isDarkMode) {
    return Container(
      height: 40,
      width: 1,
      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
    );
  }



  Widget _buildIngredients() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3748);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.kitchen,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nguyên liệu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.recipe.ingredients.map(
                (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInstructions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3748);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.list_alt,
                  color: Color(0xFFFF6B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cách làm',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.recipe.instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildFloatingActionButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "favorite",
          onPressed: _isLoading ? null : _toggleFavorite,
          backgroundColor: _isFavorite
              ? const Color(0xFFFF6B6B)
              : (isDarkMode ? Colors.grey[800] : Colors.white),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
            ),
          )
              : Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite
                ? Colors.white
                : const Color(0xFFFF6B6B),
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: "share",
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Tính năng chia sẻ sẽ có trong phiên bản sau'),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
              ),
            );
          },
          backgroundColor: const Color(0xFFFF6B6B),
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text(
            'Chia sẻ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

}
