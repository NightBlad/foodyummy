import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../models/favorite.dart';
import '../models/ingredient.dart';
import '../utils/utf8_config.dart';
import 'auto_notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AutoNotificationService _autoNotificationService = AutoNotificationService();

  // ==================== USER MANAGEMENT ====================

  // Thêm user mới
  Future<void> addUser(AppUser user) async {
    try {
      final cleanData = UTF8Config.prepareDataForFirestore(user.toMap());
      await _db.collection('users').doc(user.id).set(cleanData);
    } catch (e) {
      throw Exception('Lỗi khi thêm user: $e');
    }
  }

  // Lấy thông tin user
  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final cleanData = UTF8Config.cleanDataFromFirestore(data);
          return AppUser.fromMap(cleanData);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy user: $e');
    }
  }

  // Cập nhật thông tin user
  Future<void> updateUser(AppUser user) async {
    try {
      final cleanData = UTF8Config.prepareDataForFirestore(user.toMap());
      await _db.collection('users').doc(user.id).update(cleanData);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật user: $e');
    }
  }

  // Cập nhật thông tin user (chỉ cập nhật các trường truyền vào)
  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final cleanData = UTF8Config.prepareDataForFirestore(data);
      await _db.collection('users').doc(userId).update(cleanData);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật user: $e');
    }
  }

  // ==================== RECIPE MANAGEMENT ====================

  // Thêm công thức nấu ăn mới
  Future<String> addRecipe(Recipe recipe) async {
    try {
      // Validate imageUrl trước khi lưu
      final recipeData = UTF8Config.prepareDataForFirestore(recipe.toMap());
      if (recipeData['imageUrl'] == null ||
          recipeData['imageUrl'].toString().isEmpty ||
          recipeData['imageUrl'].toString().length < 5) {
        recipeData['imageUrl'] = ''; // Set empty string thay vì null
      }

      DocumentReference docRef = await _db
          .collection('recipes')
          .add(recipeData);

      // Cập nhật ID của recipe
      await docRef.update({'id': docRef.id});

      // Tạo recipe object với ID đã cập nhật để gửi notification
      final recipeWithId = Recipe(
        id: docRef.id,
        title: recipe.title,
        description: recipe.description,
        images: recipe.images, // Sửa từ imageUrl thành images
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        category: recipe.category,
        cookingTime: recipe.cookingTime,
        difficulty: recipe.difficulty,
        servings: recipe.servings,
        createdBy: recipe.createdBy,
        createdAt: recipe.createdAt,
        tags: recipe.tags,
        rating: recipe.rating,
        ratingCount: recipe.ratingCount,
      );

      // Gửi thông báo tự động cho tất cả users
      await _autoNotificationService.sendNewRecipeNotification(recipeWithId);

      // Gửi thông báo theo category nếu có
      if (recipe.category.isNotEmpty) {
        await _autoNotificationService.sendCategoryNotification(recipe.category, recipeWithId);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi khi thêm công thức: $e');
    }
  }

  // Lấy tất cả công thức
  Stream<List<Recipe>> getRecipes() {
    return _db
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final cleanData = UTF8Config.cleanDataFromFirestore(doc.data());
            return Recipe.fromMap(cleanData);
          }).toList(),
        );
  }

  // Lấy công thức theo ID
  Future<Recipe?> getRecipe(String recipeId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection('recipes')
          .doc(recipeId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final cleanData = UTF8Config.cleanDataFromFirestore(data);
        return Recipe.fromMap(cleanData);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy công thức: $e');
    }
  }

  // Cập nhật công thức
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final cleanData = UTF8Config.prepareDataForFirestore(recipe.toMap());
      await _db.collection('recipes').doc(recipe.id).update(cleanData);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật công thức: $e');
    }
  }

  // Xóa công thức
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _db.collection('recipes').doc(recipeId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa công thức: $e');
    }
  }

  // Tìm kiếm công thức
  Stream<List<Recipe>> searchRecipes(String query) {
    return _db
        .collection('recipes')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList(),
        );
  }

  // Lấy công thức theo danh mục
  Stream<List<Recipe>> getRecipesByCategory(String category) {
    return _db
        .collection('recipes')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList(),
        );
  }

  // Lấy công thức yêu thích của user
  Stream<List<Recipe>> getFavoriteRecipes(String userId) {
    return _db.collection('users').doc(userId).snapshots().asyncMap((
      userDoc,
    ) async {
      if (!userDoc.exists) return <Recipe>[];

      AppUser user = AppUser.fromMap(userDoc.data()!);
      if (user.favoriteRecipes.isEmpty) return <Recipe>[];

      List<Recipe> favoriteRecipes = [];
      for (String recipeId in user.favoriteRecipes) {
        Recipe? recipe = await getRecipe(recipeId);
        if (recipe != null) {
          favoriteRecipes.add(recipe);
        }
      }
      return favoriteRecipes;
    });
  }

  // Thêm/xóa công thức khỏi danh sách yêu thích
  Future<void> toggleFavoriteRecipe(String userId, String recipeId) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        AppUser user = AppUser.fromMap(userDoc.data() as Map<String, dynamic>);
        List<String> favorites = List.from(user.favoriteRecipes);

        if (favorites.contains(recipeId)) {
          favorites.remove(recipeId);
        } else {
          favorites.add(recipeId);
        }

        await userRef.update({'favoriteRecipes': favorites});
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật yêu thích: $e');
    }
  }

  // ==================== FAVORITE MANAGEMENT ====================

  Future<void> addFavorite(Favorite favorite) async {
    try {
      DocumentReference docRef = await _db
          .collection('favorites')
          .add(favorite.toMap());
      await docRef.update({'id': docRef.id});
    } catch (e) {
      throw Exception('Lỗi khi thêm món yêu thích: $e');
    }
  }

  Stream<List<Favorite>> getFavorites(String userId) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Favorite.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Favorite>> searchFavorites(String userId, String query) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Favorite.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Favorite>> filterFavoritesByType(String userId, String type) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Favorite.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateFavorite(String id, Favorite favorite) async {
    try {
      await _db.collection('favorites').doc(id).update(favorite.toMap());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật món yêu thích: $e');
    }
  }

  Future<void> deleteFavorite(String id) async {
    try {
      await _db.collection('favorites').doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa món yêu thích: $e');
    }
  }

  // ==================== INGREDIENT MANAGEMENT ====================

  Future<void> addIngredient(Ingredient ingredient) async {
    try {
      DocumentReference docRef = await _db
          .collection('ingredients')
          .add(ingredient.toMap());
      await docRef.update({'id': docRef.id});
    } catch (e) {
      throw Exception('Lỗi khi thêm nguyên liệu: $e');
    }
  }

  Future<void> deleteIngredient(String id) async {
    try {
      await _db.collection('ingredients').doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa nguyên liệu: $e');
    }
  }

  // Lấy danh mục phổ biến
  Future<List<String>> getPopularCategories() async {
    try {
      QuerySnapshot snapshot = await _db.collection('recipes').get();
      Map<String, int> categoryCount = {};

      for (var doc in snapshot.docs) {
        Recipe recipe = Recipe.fromMap(doc.data() as Map<String, dynamic>);
        categoryCount[recipe.category] =
            (categoryCount[recipe.category] ?? 0) + 1;
      }

      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.map((entry) => entry.key).take(10).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh mục: $e');
    }
  }
}
