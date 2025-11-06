import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static String? _apiKey;

  static void setApiKey(String? key) {
    _apiKey = key;
  }

  static Future<String?> getComment(
    String dreamText,
    int rating,
    String mood,
    String category,
    List<String> tags,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return null;
    }

    try {
      final prompt = _buildPrompt(dreamText, rating, mood, category, tags);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Provide a 2-3 sentence symbolic interpretation of this dream using accessible, thoughtful language.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String?;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static String _buildPrompt(
    String dreamText,
    int rating,
    String mood,
    String category,
    List<String> tags,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Dream: $dreamText');
    buffer.writeln('Rating: $rating/5');
    buffer.writeln('Mood: $mood');
    buffer.writeln('Category: $category');
    if (tags.isNotEmpty) {
      buffer.writeln('Tags: ${tags.join(", ")}');
    }
    return buffer.toString();
  }
}
