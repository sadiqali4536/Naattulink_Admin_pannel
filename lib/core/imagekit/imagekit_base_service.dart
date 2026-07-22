import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'imagekit_models.dart';
import 'imagekit_exceptions.dart';

/// Base service for interacting with ImageKit.io API.
/// Each account should instantiate or extend this with its own credentials.
class ImageKitBaseService {
  final String publicKey;
  final String privateKey;
  final String urlEndpoint;

  const ImageKitBaseService({
    required this.publicKey,
    required this.privateKey,
    required this.urlEndpoint,
  });

  /// Maximum allowed file size: 10 MB.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image file extensions.
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static const String _uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';
  static const String _apiUrl = 'https://api.imagekit.io/v1/files';

  String _getAuthHeader() {
    final credentials = base64Encode(utf8.encode('$privateKey:'));
    return 'Basic $credentials';
  }

  /// Uploads [imageBytes] to ImageKit under [folder].
  ///
  /// Returns [ImageKitUploadResult] containing imageUrl and fileId.
  /// Throws [ImageKitUploadException] on any failure.
  Future<ImageKitUploadResult> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    if (imageBytes.lengthInBytes > maxFileSizeBytes) {
      throw ImageKitUploadException(
        'Image exceeds 10 MB limit '
        '(${(imageBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB).',
      );
    }

    final authHeader = _getAuthHeader();
    final uri = Uri.parse(_uploadUrl);
    
    // Ensure folder starts with /
    final formattedFolder = folder.startsWith('/') ? folder : '/$folder';

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = authHeader
      ..fields['fileName'] = fileName
      ..fields['folder'] = formattedFolder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

    onProgress?.call(0.05);

    try {
      final streamedResponse = await request.send();

      int received = 0;
      final total = streamedResponse.contentLength ?? 1;
      final chunks = <int>[];

      await for (final chunk in streamedResponse.stream) {
        chunks.addAll(chunk);
        received += chunk.length;
        onProgress?.call((received / total).clamp(0.0, 0.90));
      }

      onProgress?.call(1.0);

      final responseBody = utf8.decode(chunks);

      if (streamedResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        final result = ImageKitUploadResult.fromJson(data);
        
        if (result.imageUrl.isNotEmpty && result.fileId.isNotEmpty) {
          return result;
        }
        throw ImageKitUploadException(
          'Upload succeeded but missing URL or fileId in response.',
        );
      } else {
        String errorMessage = 'HTTP ${streamedResponse.statusCode}';
        try {
          final Map<String, dynamic> errData = json.decode(responseBody);
          errorMessage = errData['message'] ?? errData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = '$errorMessage — $responseBody';
        }
        throw ImageKitUploadException('ImageKit upload failed: $errorMessage');
      }
    } catch (e) {
      if (e is ImageKitException) rethrow;
      throw ImageKitUploadException('Network error during upload: $e');
    }
  }

  /// Deletes an image from ImageKit using its [fileId].
  ///
  /// Throws [ImageKitDeleteException] on failure.
  Future<void> deleteImage(String fileId) async {
    if (fileId.isEmpty) {
      throw const ImageKitDeleteException('File ID cannot be empty');
    }

    final authHeader = _getAuthHeader();
    final uri = Uri.parse('$_apiUrl/$fileId');

    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': authHeader},
      );

      if (response.statusCode != 204) {
        String errorMessage = 'HTTP ${response.statusCode}';
        try {
          final Map<String, dynamic> errData = json.decode(response.body);
          errorMessage = errData['message'] ?? errData['error'] ?? errorMessage;
        } catch (_) {
          errorMessage = '$errorMessage — ${response.body}';
        }
        throw ImageKitDeleteException('ImageKit delete failed: $errorMessage');
      }
    } catch (e) {
      if (e is ImageKitException) rethrow;
      throw ImageKitDeleteException('Network error during delete: $e');
    }
  }

  /// Builds a full CDN URL for a given relative file path.
  String getUrl(String filePath) {
    final base = urlEndpoint.endsWith('/') ? urlEndpoint : '$urlEndpoint/';
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$base$path';
  }

  /// Generates a safe, timestamped filename preserving the original extension.
  String generateFileName(String originalName, String prefix) {
    final ext = originalName.split('.').last.toLowerCase();
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  /// Returns true if the file extension is allowed.
  static bool isAllowedExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }
}
