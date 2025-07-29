import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class UsageLimitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection =
      'users'; // Sử dụng collection users thay vì usage_limits

  // Giới hạn số lần tạo công thức AI
  static const int _userDailyLimit = 1;
  static const int _adminDailyLimit = 5;

  // Kiểm tra xem user có thể tạo công thức AI không
  static Future<bool> canGenerateRecipe() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    try {
      final userDoc = await _firestore
          .collection(_collection)
          .doc(currentUser.id)
          .get();

      if (!userDoc.exists) {
        return true; // User mới - luôn có thể sử dụng
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Kiểm tra quyền admin
      final isAdmin =
          userData['role'] == 'admin' || userData['isAdmin'] == true;
      final dailyLimit = isAdmin ? _adminDailyLimit : _userDailyLimit;

      // Lấy usage data
      final usageData = userData['ai_usage'] as Map<String, dynamic>?;
      if (usageData == null) {
        return true; // Chưa có data usage
      }

      final todayUsage = usageData[todayKey] as Map<String, dynamic>?;
      if (todayUsage == null) {
        return true; // Chưa sử dụng hôm nay
      }

      final aiRecipeCount = todayUsage['count'] as int? ?? 0;
      return aiRecipeCount < dailyLimit;
    } catch (e) {
      print('Error checking usage limit: $e');
      return true; // Nếu có lỗi, cho phép sử dụng
    }
  }

  // Lấy thông tin usage hiện tại
  static Future<Map<String, int>> getCurrentUsage() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      return {'used': 0, 'limit': _userDailyLimit};
    }

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    try {
      final userDoc = await _firestore
          .collection(_collection)
          .doc(currentUser.id)
          .get();

      if (!userDoc.exists) {
        return {'used': 0, 'limit': _userDailyLimit};
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Kiểm tra quyền admin
      final isAdmin =
          userData['role'] == 'admin' || userData['isAdmin'] == true;
      final dailyLimit = isAdmin ? _adminDailyLimit : _userDailyLimit;

      // Lấy usage data
      final usageData = userData['ai_usage'] as Map<String, dynamic>?;
      if (usageData == null) {
        return {'used': 0, 'limit': dailyLimit};
      }

      final todayUsage = usageData[todayKey] as Map<String, dynamic>?;
      if (todayUsage == null) {
        return {'used': 0, 'limit': dailyLimit};
      }

      final aiRecipeCount = todayUsage['count'] as int? ?? 0;
      return {'used': aiRecipeCount, 'limit': dailyLimit};
    } catch (e) {
      print('Error getting current usage: $e');
      return {'used': 0, 'limit': _userDailyLimit};
    }
  }

  // Ghi nhận việc sử dụng tạo công thức AI
  static Future<void> recordAIRecipeUsage() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    try {
      final docRef = _firestore.collection(_collection).doc(currentUser.id);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        Map<String, dynamic> userData = {};
        if (doc.exists) {
          userData = doc.data() as Map<String, dynamic>;
        }

        // Lấy hoặc tạo ai_usage data
        Map<String, dynamic> aiUsage = {};
        if (userData.containsKey('ai_usage')) {
          aiUsage = Map<String, dynamic>.from(userData['ai_usage']);
        }

        // Lấy hoặc tạo dữ liệu cho ngày hôm nay
        Map<String, dynamic> todayData = {};
        if (aiUsage.containsKey(todayKey)) {
          todayData = Map<String, dynamic>.from(aiUsage[todayKey]);
        }

        // Tăng counter
        final currentCount = todayData['count'] as int? ?? 0;
        todayData['count'] = currentCount + 1;
        todayData['last_used'] = FieldValue.serverTimestamp();

        // Cập nhật data
        aiUsage[todayKey] = todayData;
        userData['ai_usage'] = aiUsage;
        userData['updated_at'] = FieldValue.serverTimestamp();

        // Đảm bảo có các field cơ bản
        if (!userData.containsKey('email')) {
          userData['email'] = currentUser.email;
        }
        if (!userData.containsKey('name')) {
          userData['name'] = currentUser.name;
        }
        if (!userData.containsKey('role')) {
          userData['role'] = 'user';
        }

        transaction.set(docRef, userData);
      });
    } catch (e) {
      print('Error recording AI recipe usage: $e');
      throw Exception('Không thể ghi nhận việc sử dụng: $e');
    }
  }

  // Reset usage (chỉ admin hoặc system có thể gọi)
  static Future<void> resetUserUsage(String userId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(userId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;
          userData.remove('ai_usage');
          transaction.update(docRef, userData);
        }
      });
    } catch (e) {
      print('Error resetting user usage: $e');
      throw Exception('Không thể reset usage: $e');
    }
  }

  // Lấy thống kê usage cho admin
  static Future<List<Map<String, dynamic>>> getUsageStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      List<Map<String, dynamic>> statistics = [];
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';

      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;
        final userName =
            userData['name'] ?? userData['displayName'] ?? 'Unknown User';

        int todayUsage = 0;
        DateTime? lastUsed;

        if (userData.containsKey('ai_usage')) {
          final aiUsage = userData['ai_usage'] as Map<String, dynamic>;
          if (aiUsage.containsKey(todayKey)) {
            final todayData = aiUsage[todayKey] as Map<String, dynamic>;
            todayUsage = todayData['count'] as int? ?? 0;
            lastUsed = (todayData['last_used'] as Timestamp?)?.toDate();
          }
        }

        statistics.add({
          'userId': userId,
          'userName': userName,
          'todayUsage': todayUsage,
          'lastUsed': lastUsed,
        });
      }

      return statistics;
    } catch (e) {
      print('Error getting usage statistics: $e');
      return [];
    }
  }
}
