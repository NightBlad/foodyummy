import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey =
      'AIzaSyDHD8JNKZ4ONvPAAOCwkYlIQJTTRd6_BkU'; // Thay thế bằng API key thực tế
  static GenerativeModel? _model;

  // Khởi tạo Gemini model
  static GenerativeModel get _getModel {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash', // Hoặc 'gemini-1.5-pro' cho chất lượng cao hơn
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    return _model!;
  }

  static Future<Map<String, dynamic>?> generateRecipeFromIngredients({
    required List<String> ingredients,
    String? additionalRequirements,
  }) async {
    try {
      final prompt = _buildPrompt(ingredients, additionalRequirements);

      final content = [Content.text(prompt)];
      final response = await _getModel.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return _parseRecipeFromText(response.text!);
      } else {
        print('Gemini API returned empty response');
        return null;
      }
    } catch (e) {
      print('Exception in Gemini service: $e');
      return null;
    }
  }

  static String _buildPrompt(
    List<String> ingredients,
    String? additionalRequirements,
  ) {
    String prompt =
        '''
Bạn là một đầu bếp chuyên nghiệp. Hãy tạo một công thức nấu ăn sử dụng các nguyên liệu sau: ${ingredients.join(', ')}

${additionalRequirements != null ? 'Yêu cầu thêm: $additionalRequirements' : ''}

Vui lòng trả về kết quả theo định dạng JSON sau (chỉ trả về JSON, không thêm text khác):
{
  "title": "Tên món ăn",
  "description": "Mô tả ngắn gọn về món ăn",
  "category": "Danh mục món ăn (ví dụ: Món chính, Món tráng miệng, Món ăn nhẹ)",
  "cookingTime": 30,
  "servings": 4,
  "difficulty": "easy",
  "ingredients": [
    "Nguyên liệu 1 - số lượng cụ thể",
    "Nguyên liệu 2 - số lượng cụ thể"
  ],
  "instructions": [
    "Bước 1: Mô tả chi tiết",
    "Bước 2: Mô tả chi tiết",
    "Bước 3: Mô tả chi tiết"
  ],
  "tags": ["tag1", "tag2", "tag3"]
}

Yêu cầu:
- Sử dụng tất cả nguyên liệu đã cho
- Có thể thêm một số nguyên liệu phổ biến khác nếu cần
- Các bước thực hiện phải chi tiết và dễ hiểu
- cookingTime là số phút (number)
- servings là số người ăn (number)
- difficulty phải là "easy", "medium" hoặc "hard"
- Trả về CHÍNH XÁC theo định dạng JSON trên, không thêm markdown hoặc text khác
''';
    return prompt;
  }

  static Map<String, dynamic>? _parseRecipeFromText(String text) {
    try {
      // Tìm và extract JSON từ response
      String jsonString = text.trim();

      // Loại bỏ markdown nếu có
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      }
      if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }

      // Tìm JSON object
      final jsonStart = jsonString.indexOf('{');
      final jsonEnd = jsonString.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == -1) {
        print('Could not find valid JSON in response: $text');
        return null;
      }

      jsonString = jsonString.substring(jsonStart, jsonEnd);
      final parsed = jsonDecode(jsonString);

      // Validate required fields
      if (parsed['title'] == null ||
          parsed['ingredients'] == null ||
          parsed['instructions'] == null) {
        print('Missing required fields in parsed recipe');
        return null;
      }

      return {
        'title': parsed['title'] ?? '',
        'description': parsed['description'] ?? '',
        'category': parsed['category'] ?? 'Món chính',
        'cookingTime': _parseTimeToMinutes(parsed['cookingTime']),
        'servings': _parseServings(parsed['servings']),
        'difficulty': _validateDifficulty(parsed['difficulty']),
        'ingredients': List<String>.from(parsed['ingredients'] ?? []),
        'instructions': List<String>.from(parsed['instructions'] ?? []),
        'tags': List<String>.from(parsed['tags'] ?? []),
      };
    } catch (e) {
      print('Error parsing recipe from text: $e');
      print('Original text: $text');
      return null;
    }
  }

  static int _parseTimeToMinutes(dynamic time) {
    if (time is int) return time;
    if (time is String) {
      final numbers = RegExp(r'\d+').allMatches(time);
      if (numbers.isNotEmpty) {
        return int.tryParse(numbers.first.group(0)!) ?? 30;
      }
    }
    return 30; // Default time
  }

  static int _parseServings(dynamic servings) {
    if (servings is int) return servings;
    if (servings is String) {
      final numbers = RegExp(r'\d+').allMatches(servings);
      if (numbers.isNotEmpty) {
        return int.tryParse(numbers.first.group(0)!) ?? 4;
      }
    }
    return 4; // Default servings
  }

  static String _validateDifficulty(dynamic difficulty) {
    if (difficulty is String) {
      final lower = difficulty.toLowerCase();
      if (['easy', 'medium', 'hard'].contains(lower)) {
        return lower;
      }
    }
    return 'medium'; // Default difficulty
  }
}
