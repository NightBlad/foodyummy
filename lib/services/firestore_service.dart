import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../models/favorite.dart';
import '../models/ingredient.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USER MANAGEMENT ====================

  // Thêm user mới
  Future<void> addUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
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
          return AppUser.fromMap(data);
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
      await _db.collection('users').doc(user.id).update(user.toMap());
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
      await _db.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật user: $e');
    }
  }

  // ==================== RECIPE MANAGEMENT ====================

  // Thêm công thức nấu ăn mới
  Future<String> addRecipe(Recipe recipe) async {
    try {
      DocumentReference docRef = await _db
          .collection('recipes')
          .add(recipe.toMap());

      // Cập nhật ID của recipe
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi khi thêm công thức: $e');
    }
  }

  // Lấy tất cả công th��c
  Stream<List<Recipe>> getRecipes() {
    return _db
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList(),
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
        return Recipe.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy công thức: $e');
    }
  }

  // Cập nhật công thức
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _db.collection('recipes').doc(recipe.id).update(recipe.toMap());
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
