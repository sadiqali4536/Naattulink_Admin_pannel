import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for uploading images to ImageKit.io via the REST upload API.
///
/// Uses Basic Auth with the private key — no backend server or "unsigned uploads"
/// setting required. This is acceptable for an admin-only internal panel.
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │  SETUP: Paste your ImageKit PRIVATE KEY below (_privateKey).   │
/// │  Find it at: imagekit.io/dashboard → Developer → API Keys      │
/// └─────────────────────────────────────────────────────────────────┘
class ImageKitService {
  // ─── Configuration ────────────────────────────────────────────────────────

  /// Your ImageKit PRIVATE Key.
  /// ⚠️ Keep this in admin code only — never expose in a public mobile app.
  /// Find it at: https://imagekit.io/dashboard/developer/api-keys
  static const String _privateKey = 'private_KgiMaSuYgh1Xx4Q8ZBOydkQdFx0=';

  /// Your ImageKit URL Endpoint (read-only, used for CDN URLs).
  static const String _urlEndpoint = 'https://ik.imagekit.io/naattulink';

  /// ImageKit V1 Upload API endpoint.
  static const String _uploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';

  // ─── Limits & validation ──────────────────────────────────────────────────

  /// Maximum allowed file size: 10 MB.
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Allowed image file extensions.
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  // ─── Upload ───────────────────────────────────────────────────────────────

  /// Uploads [imageBytes] to ImageKit under [folder].
  ///
  /// [fileName]   — include extension, e.g. `banner_12345.png`
  /// [folder]     — destination folder, e.g. `banners` or `local_products`
  /// [onProgress] — reports progress from 0.0 → 1.0
  ///
  /// Returns the ImageKit CDN URL of the uploaded image.
  /// Throws [ImageKitUploadException] on any failure.
  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String folder = 'banners',
    void Function(double progress)? onProgress,
  }) async {
    // ── 1. Validate ─────────────────────────────────────────────────────────
    if (imageBytes.lengthInBytes > maxFileSizeBytes) {
      throw ImageKitUploadException(
        'Image exceeds 10 MB limit '
        '(${(imageBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB).',
      );
    }

    // ── 2. Build Basic Auth header ──────────────────────────────────────────
    // ImageKit server-side upload uses HTTP Basic Auth:
    //   username = privateKey,  password = "" (empty string)
    final credentials = base64Encode(utf8.encode('$_privateKey:'));
    final authHeader = 'Basic $credentials';

    // ── 3. Build multipart request ──────────────────────────────────────────
    final uri = Uri.parse(_uploadUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = authHeader
      ..fields['fileName'] = fileName
      ..fields['folder'] = '/$folder'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

    // ── 4. Send & collect response ──────────────────────────────────────────
    onProgress?.call(0.05);

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

    // ── 5. Parse response ───────────────────────────────────────────────────
    final responseBody = utf8.decode(chunks);

    if (streamedResponse.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(responseBody);
      final String? url = data['url'] as String?;
      if (url != null && url.isNotEmpty) {
        return url;
      }
      throw ImageKitUploadException(
        'Upload succeeded but no URL in response. Body: $responseBody',
      );
    } else {
      // Extract error message from ImageKit response JSON
      String errorMessage = 'HTTP ${streamedResponse.statusCode}';
      try {
        final Map<String, dynamic> errData = json.decode(responseBody);
        errorMessage = errData['message'] ?? errData['error'] ?? errorMessage;
      } catch (_) {
        errorMessage = '$errorMessage — $responseBody';
      }
      throw ImageKitUploadException('ImageKit upload failed: $errorMessage');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Generates a safe, timestamped filename preserving the original extension.
  /// Example: generateFileName('photo.JPG', 'banner') → 'banner_1720000000000.jpg'
  static String generateFileName(String originalName, String prefix) {
    final ext = originalName.split('.').last.toLowerCase();
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
  }

  /// Returns true if the file extension is allowed.
  static bool isAllowedExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(ext);
  }

  /// Builds a full CDN URL for a given relative file path.
  /// Example: getUrl('banners/banner_123.png')
  ///       → 'https://ik.imagekit.io/naattulink/banners/banner_123.png'
  static String getUrl(String filePath) {
    final base = _urlEndpoint.endsWith('/') ? _urlEndpoint : '$_urlEndpoint/';
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$base$path';
  }
}

// ─── Exception ───────────────────────────────────────────────────────────────

/// Thrown when an ImageKit upload operation fails.
class ImageKitUploadException implements Exception {
  final String message;
  const ImageKitUploadException(this.message);

  @override
  String toString() => 'ImageKitUploadException: $message';
}
