import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'recipes';

  // Thêm công thức mới
  static Future<void> addRecipe(Recipe recipe) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(recipe.id)
          .set(recipe.toMap());
    } catch (e) {
      throw Exception('Lỗi khi thêm công thức: $e');
    }
  }

  // Lấy tất cả công thức
  static Future<List<Recipe>> getAllRecipes() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Thêm id vào data
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách công thức: $e');
    }
  }

  // Lấy công thức theo category
  static Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Thêm id vào data
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy công thức theo danh mục: $e');
    }
  }

  // Lấy công thức của user
  static Future<List<Recipe>> getUserRecipes(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Thêm id vào data
        return Recipe.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy công thức của người dùng: $e');
    }
  }

  // Cập nhật công thức
  static Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(recipe.id)
          .update(recipe.toMap());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật công thức: $e');
    }
  }

  // Xóa công thức
  static Future<void> deleteRecipe(String recipeId) async {
    try {
      await _firestore.collection(_collection).doc(recipeId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa công thức: $e');
    }
  }

  // Tìm kiếm công thức
  static Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      final allRecipes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Thêm id vào data
        return Recipe.fromMap(data);
      }).toList();

      // Filter recipes based on title, description, or ingredients
      final filteredRecipes = allRecipes.where((recipe) {
        final searchLower = query.toLowerCase();
        return recipe.title.toLowerCase().contains(searchLower) ||
            recipe.description.toLowerCase().contains(searchLower) ||
            recipe.ingredients.any(
              (ingredient) => ingredient.toLowerCase().contains(searchLower),
            ) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();

      return filteredRecipes;
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm công thức: $e');
    }
  }
}
