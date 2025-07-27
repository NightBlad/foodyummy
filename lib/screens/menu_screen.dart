import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/hybrid_image_widget.dart';
import 'recipe_detail_screen.dart';
import 'add_recipe_screen.dart';
import 'admin_panel_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  final bool _showFavoritesOnly = false;
  AppUser? _currentUser;

  final List<String> _categories = [
    'Tất cả',
    'Món chính',
    'Món phụ',
    'Tráng miệng',
    'Đồ uống',
    'Món ăn sáng',
    'Món ăn nhẹ',
    'Súp',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: const Duration(
        milliseconds: 400,
      ), // Hiệu ứng chuyển tab mượt hơn
    );
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUser(user.uid);
      if (mounted) { // Kiểm tra widget còn mounted trước khi setState
        setState(() {
          _currentUser = userData;
        });
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: _currentUser?.name ?? '',
    );
    final emailController = TextEditingController(
      text: _currentUser?.email ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin cá nhân'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: false, // Không cho sửa email ở đây
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await _firestoreService.updateUserFields(_currentUser!.id, {
                    'name': nameController.text.trim(),
                  });
                  if (mounted) {
                    setState(() {
                      _currentUser = _currentUser!.copyWith(
                        name: nameController.text.trim(),
                      );
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi cập nhật: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _currentUser?.isAdmin == true;
    return AnimatedTheme(
      data: Theme.of(context),
      duration: const Duration(milliseconds: 10),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? null
                : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
            ),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : null,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildCategoryTabs(isAdmin: isAdmin),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 10),
                    child: TabBarView(
                      key: ValueKey(_tabController.length),
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildRecipeList(),
                        _buildFavoritesList(),
                        _buildCategoriesGrid(),
                        _buildProfileTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào! 👋',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  _currentUser?.name ?? 'Food Lover',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFFFF6B6B),
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.logout, color: Color(0xFFFF6B6B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm công thức nấu ăn...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFFFF6B6B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: isDarkMode ? Colors.white : Colors.grey,
            ),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryTabs({bool isAdmin = false}) {
    final tabs = [
      const Tab(icon: Icon(Icons.home), text: 'Trang chủ'),
      const Tab(icon: Icon(Icons.favorite), text: 'Yêu thích'),
      const Tab(icon: Icon(Icons.category), text: 'Danh mục'),
      const Tab(icon: Icon(Icons.person), text: 'Cá nhân'),
    ];

    if (_tabController.length != 4) {
      _tabController.dispose();
      _tabController = TabController(
        length: 4,
        vsync: this,
        animationDuration: const Duration(milliseconds: 400),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: const Color(0xFFFF6B6B),
        unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
        indicatorColor: const Color(0xFFFF6B6B),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: tabs,
      ),
    );
  }


  Widget _buildCategoryFilter() {
    // Bộ lọc category dạng horizontal scroll, chỉ hiển thị ở tab Trang chủ
    if (_tabController.index != 0) return const SizedBox.shrink();
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6B6B)
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeList() {
    return StreamBuilder<List<Recipe>>(
      key: ValueKey('${_searchQuery}_${_selectedCategory}'), // Key để force rebuild khi filter thay đổi
      stream: _searchQuery.isNotEmpty
          ? _firestoreService.searchRecipes(_searchQuery)
          : _selectedCategory == 'Tất cả'
          ? _firestoreService.getRecipes()
          : _firestoreService.getRecipesByCategory(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          String message = 'Không có công thức nào';
          if (_searchQuery.isNotEmpty) {
            message = 'Không tìm thấy công thức cho "$_searchQuery"';
          } else if (_selectedCategory != 'Tất cả') {
            message = 'Chưa có công thức nào trong danh mục "$_selectedCategory"';
          }
          return _buildEmptyState(message: message);
        }

        return Column(
          children: [
            _buildCategoryFilter(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return _buildRecipeCard(snapshot.data![index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe image
              Container(
                height: 200,
                width: double.infinity,
                child: recipe.imageUrl.isNotEmpty
                    ? Stack(
                        children: [
                          HybridImageWidget(
                            imagePath: recipe.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _currentUser?.favoriteRecipes.contains(
                                    recipe.id,
                                  ) ==
                                      true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: const Color(0xFFFF6B6B),
                                ),
                                onPressed: () {
                                  if (_currentUser != null) {
                                    _firestoreService.toggleFavoriteRecipe(
                                      _currentUser!.id,
                                      recipe.id,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                      ),
              ),

              // Recipe info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            recipe.category,
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.access_time,
                          '${recipe.cookingTime} phút',
                        ),
                        const SizedBox(width: 16),
                        _buildInfoChip(
                          Icons.people,
                          '${recipe.servings} người',
                        ),
                        const SizedBox(width: 16),
                        _buildInfoChip(
                          Icons.signal_cellular_alt,
                          recipe.difficulty == 'easy'
                              ? 'Dễ'
                              : recipe.difficulty == 'medium'
                              ? 'Trung bình'
                              : 'Khó',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildFavoritesList() {
    if (_currentUser == null) {
      return const Center(child: Text('Vui lòng đăng nhập để xem yêu thích'));
    }

    return StreamBuilder<List<Recipe>>(
      stream: _firestoreService.getFavoriteRecipes(_currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(message: 'Chưa có công thức yêu thích nào');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildRecipeCard(snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _categories.length - 1,
      itemBuilder: (context, index) {
        final category = _categories[index + 1];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(String category) {
    final icons = {
      'Món chính': Icons.restaurant,
      'Món phụ': Icons.lunch_dining,
      'Tráng miệng': Icons.cake,
      'Đồ uống': Icons.local_drink,
      'Món ăn sáng': Icons.breakfast_dining,
      'Món ăn nhẹ': Icons.fastfood,
      'Súp': Icons.soup_kitchen,
    };

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _tabController.animateTo(0);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[category] ?? Icons.restaurant,
                size: 40,
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }


  Widget _buildProfileTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header
          Container(
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
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentUser?.name ?? 'User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  _currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                if (_currentUser?.isAdmin == true)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Chức năng Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.deepPurple
                          : Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminPanelScreen(),
                        ),
                      );
                    },
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      'Công thức',
                      '${_currentUser?.recipesCreated ?? 0}',
                      isDarkMode,
                    ),
                    _buildStatItem(
                      'Yêu thích',
                      '${_currentUser?.favoriteRecipes.length ?? 0}',
                      isDarkMode,
                    ),
                    _buildStatItem(
                      'Cấp độ',
                      _currentUser?.isAdmin == true ? 'Admin' : 'User',
                      isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu items
          _buildMenuItem(
            Icons.edit,
            'Chỉnh sửa thông tin',
            _showEditProfileDialog,
          ),
          _buildMenuItem(Icons.settings, 'Cài đặt', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }),
          _buildMenuItem(Icons.help, 'Trợ giúp', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            );
          }),
          _buildMenuItem(Icons.logout, 'Đăng xuất', () async {
            await FirebaseAuth.instance.signOut();
          }),
        ],
      ),
    );
  }


  Widget _buildStatItem(String label, String value, bool isDarkMode) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B6B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
      ],
    );
  }


  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFFF6B6B),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
        onTap: onTap,
      ),
    );
  }


  Widget _buildEmptyState({String message = 'Không có công thức nào'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
        );
      },
      backgroundColor: const Color(0xFFFF6B6B),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Thêm công thức',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
