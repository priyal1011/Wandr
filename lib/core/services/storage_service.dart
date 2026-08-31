import 'cloudinary_service.dart';

class StorageService {
  /// Uploads to Cloudinary (Free Sync)
  static Future<String?> uploadImage(String localPath, String folder) async {
    // We direct the traffic to Cloudinary for free sync without credit card
    return await CloudinaryService.uploadImage(localPath);
  }
}
