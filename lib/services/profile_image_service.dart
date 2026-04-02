import 'dart:convert';
import 'dart:typed_data';

import 'package:ewallet/services/api_service.dart';
import 'package:http/http.dart' as http;

class ProfileImageService {
  Future<String> uploadProfileImage({
    required Uint8List imageBytes,
    required String fileName,
    required String contentType,
  }) async {
    final token = await ApiService.getIdToken();

    final response = await http.post(
      ApiService.uri('/upload-profile-image'),
      headers: {
        ...ApiService.getAuthHeaders(),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fileName': fileName,
        'contentType': contentType,
        'imageData': base64Encode(imageBytes),
      }),
    );

    final data = ApiService.decodeJsonObject(
      endpoint: '/upload-profile-image',
      response: response,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Upload failed');
    }

    final imageUrl = data['imageUrl']?.toString() ?? '';
    if (imageUrl.isEmpty) {
      throw Exception('Missing image URL');
    }

    return imageUrl;
  }
}
