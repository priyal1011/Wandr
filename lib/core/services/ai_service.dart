import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../in_memory_store.dart';

class AiService {
  static const String _apiKey = 'AIzaSyAGKBDfoQt8pfCzxFMwFOJyPfw3DqpR1g8';

  static Future<List<DayData>?> generateItinerary({
    required String destination,
    required int days,
    required DateTime startDate,
    String customPrompt = '',
    String predefinedKey = '',
  }) async {
    return _callGemini(_getPrompt(destination, days, startDate, customPrompt));
  }

  /// NEW FEATURE: Add more activities to an existing day!
  static Future<List<PlaceData>?> addMorePlaces({
    required String destination,
    required DateTime date,
  }) async {
    final String prompt = '''
Plan 3 ADDITIONAL unique, high-quality activities or hidden gems in $destination for the date ${date.toIso8601String()}.
Return ONLY raw JSON in this structure:
[
  {
    "date": "${date.toIso8601String()}",
    "places": [{"name": "Specific Name", "time": "11:00 AM", "type": "Activity", "notes": "Why it's cool"}]
  }
]
''';
    try {
      final List<DayData>? result = await _callGemini(prompt);
      if (result != null && result.isNotEmpty) {
        return result.first.places;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<DayData>?> _callGemini(String prompt) async {
    try {
      debugPrint('[Wandr AI] Sending Request to Gemini...');
      const String modelName = 'gemini-3.1-flash-lite-preview';
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
             'temperature': 0.7,
             'maxOutputTokens': 2048
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (text != null) {
          debugPrint('[Wandr AI] Received Response. Length: ${text.length}');
          return _parseJson(text);
        }
      } else {
        debugPrint('[Wandr AI] HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[Wandr AI] Critical Exception: $e');
    }
    return null;
  }

  static String _getPrompt(String destination, int days, DateTime startDate, String customPrompt) {
    return '''
Create a $days-day travel itinerary for $destination starting ${startDate.toIso8601String().split('T')[0]}.
Requirement: $customPrompt
For each day, provide 4-5 diverse activities (Sightseeing, Food, Culture).
Return ONLY a raw JSON array. No markdown. No intro text.

JSON Structure:
[
  {
    "date": "YYYY-MM-DD",
    "places": [
      {"name": "Landmark Name", "time": "10:00 AM", "type": "Activity", "notes": "Short tip"}
    ]
  }
]
''';
  }

  static List<DayData>? _parseJson(String text) {
    String rawJson = text.trim();
    if (rawJson.contains('```')) {
      final parts = rawJson.split('```');
      for (var part in parts) {
        String sanitized = part.trim();
        if (sanitized.startsWith('[') || sanitized.startsWith('json')) {
          rawJson = sanitized;
          if (rawJson.startsWith('json')) rawJson = rawJson.substring(4).trim();
          break;
        }
      }
    }
    try {
      final List<dynamic> decoded = jsonDecode(rawJson);
      return decoded.map((e) => DayData.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
