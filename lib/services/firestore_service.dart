import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient.dart';
import '../models/favorite.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ingredient CRUD
  Future<void> addIngredient(String userId, Ingredient ingredient) async {
    await _db.collection('ingredients').add({
      ...ingredient.toMap(),
      'userId': userId,
    });
  }

  Future<void> updateIngredient(String id, Ingredient ingredient) async {
    await _db.collection('ingredients').doc(id).update(ingredient.toMap());
  }

  Future<void> deleteIngredient(String id) async {
    await _db.collection('ingredients').doc(id).delete();
  }

  Stream<List<Ingredient>> getIngredients(String userId) {
    return _db.collection('ingredients')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Ingredient.fromMap(doc.data(), doc.id)).toList());
  }

  // Search ingredients by name
  Stream<List<Ingredient>> searchIngredients(String userId, String query) {
    return _db.collection('ingredients')
      .where('userId', isEqualTo: userId)
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThanOrEqualTo: query + '\uf8ff')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Ingredient.fromMap(doc.data(), doc.id)).toList());
  }

  // Favorite CRUD
  Future<void> addFavorite(Favorite favorite) async {
    await _db.collection('favorites').add(favorite.toMap());
  }

  Future<void> updateFavorite(String id, Favorite favorite) async {
    await _db.collection('favorites').doc(id).update(favorite.toMap());
  }

  Future<void> deleteFavorite(String id) async {
    await _db.collection('favorites').doc(id).delete();
  }

  Stream<List<Favorite>> getFavorites(String userId) {
    return _db.collection('favorites')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Favorite.fromMap(doc.data(), doc.id)).toList());
  }

  // Search favorites by name
  Stream<List<Favorite>> searchFavorites(String userId, String query) {
    return _db.collection('favorites')
      .where('userId', isEqualTo: userId)
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThanOrEqualTo: query + '\uf8ff')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Favorite.fromMap(doc.data(), doc.id)).toList());
  }

  // Filter favorites by type
  Stream<List<Favorite>> filterFavoritesByType(String userId, String type) {
    return _db.collection('favorites')
      .where('userId', isEqualTo: userId)
      .where('type', isEqualTo: type)
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Favorite.fromMap(doc.data(), doc.id)).toList());
  }

  // User CRUD (basic)
  Future<void> addUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String id) async {
    var doc = await _db.collection('users').doc(id).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
