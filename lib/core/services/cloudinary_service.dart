import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Uploads a local file to Cloudinary and returns the public URL.
  static Future<String?> uploadImage(String localPath) async {
    try {
      final File file = File(localPath);
      if (!await file.exists()) return null;

      final Uri url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      // Note: For Cloudinary, we'll use a simple unsigned upload if possible, 
      // or signed if needed. For now, let's try the direct multipart request.
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['api_key'] = _apiKey
        ..files.add(await http.MultipartFile.fromPath('file', localPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final String? secureUrl = decoded['secure_url'];
        debugPrint('[Cloudinary] Upload Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('[Cloudinary] Upload Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Cloudinary] Exception: $e');
      return null;
    }
  }
}
