import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'dezn2hperc', // Your Cloud Name
    'agribenta_unsigned', // Your Preset Name
    cache: false,
  );

  // For livestock listings (multiple images)
  static Future<List<String>?> uploadLivestockImages(List<File> images) async {
    if (images.isEmpty) return [];

    List<String> urls = [];
    for (var image in images) {
      try {
        final response = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'agribenta_livestockapp',
          ),
        );
        urls.add(response.secureUrl);
      } catch (e) {
        print('Cloudinary upload error (listing): $e');
        return null;
      }
    }
    return urls;
  }

  // For profile picture (single image)
  static Future<String?> uploadProfileImage(File image) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'agribenta_livestockapp',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error (profile): $e');
      return null;
    }
  }
}
