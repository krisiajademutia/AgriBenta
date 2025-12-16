import 'dart:io';
import 'package:dio/dio.dart';

class ImgBBService {
  static const String apiKey =
      '7153706809c25e5afba9521b8a500079'; // Paste your key

  static Future<List<String>?> uploadLivestockImages(List<File> images) async {
    if (images.isEmpty) return [];

    List<String> urls = [];
    final dio = Dio();

    for (var image in images) {
      try {
        FormData formData = FormData.fromMap({
          'key': apiKey,
          'image': await MultipartFile.fromFile(image.path),
        });

        Response response = await dio.post(
          'https://api.imgbb.com/1/upload',
          data: formData,
        );

        if (response.statusCode == 200) {
          urls.add(response.data['data']['url']);
        } else {
          print('ImgBB upload failed: ${response.data}');
          return null;
        }
      } catch (e) {
        print('ImgBB error (listing): $e');
        return null;
      }
    }
    return urls;
  }

  static Future<String?> uploadProfileImage(File image) async {
    try {
      FormData formData = FormData.fromMap({
        'key': apiKey,
        'image': await MultipartFile.fromFile(image.path),
      });

      Response response = await Dio().post(
        'https://api.imgbb.com/1/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['data']['url'];
      }
      print('ImgBB profile failed: ${response.data}');
      return null;
    } catch (e) {
      print('ImgBB error (profile): $e');
      return null;
    }
  }
}
