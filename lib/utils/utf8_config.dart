import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UTF8Config {
  // Cấu hình UTF-8 cho Firestore
  static void configureFirestore() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      sslEnabled: true,
    );
  }

  // Encode string để đảm bảo UTF-8
  static String encodeUTF8(String text) {
    List<int> bytes = utf8.encode(text);
    return utf8.decode(bytes);
  }

  // Decode string từ Firestore
  static String decodeFromFirestore(dynamic data) {
    if (data == null) return '';

    if (data is String) {
      try {
        // Thử decode nếu string bị encode sai
        return utf8.decode(data.codeUnits);
      } catch (e) {
        // Nếu không decode được thì trả về string gốc
        return data;
      }
    }

    return data.toString();
  }

  // Prepare data trước khi lưu vào Firestore
  static Map<String, dynamic> prepareDataForFirestore(Map<String, dynamic> data) {
    Map<String, dynamic> result = {};

    data.forEach((key, value) {
      if (value is String) {
        result[key] = encodeUTF8(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is String) {
            return encodeUTF8(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  // Clean data sau khi lấy từ Firestore
  static Map<String, dynamic> cleanDataFromFirestore(Map<String, dynamic> data) {
    Map<String, dynamic> result = {};

    data.forEach((key, value) {
      if (value is String) {
        result[key] = decodeFromFirestore(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is String) {
            return decodeFromFirestore(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });

    return result;
  }
}
