import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  Future<String?> uploadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await _uploadBytes(bytes, file.path.split('/').last);
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadImageBytes(Uint8List bytes, String filename) async {
    return await _uploadBytes(bytes, filename);
  }

  Future<String?> _uploadBytes(Uint8List bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'upload_preset': AppConstants.cloudinaryUploadPreset,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
        'folder': 'swipe_app/profiles',
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete image using public_id
  Future<bool> deleteImage(String publicId) async {
    try {
      // Note: Deletion via API requires signed requests.
      // This is a placeholder — implement if needed.
      return false;
    } catch (e) {
      return false;
    }
  }
}
