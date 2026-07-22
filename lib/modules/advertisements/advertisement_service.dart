import 'dart:typed_data';
import '../../../core/imagekit/imagekit_account1.dart';
import '../../../core/imagekit/imagekit_models.dart';

/// Service for handling Advertisement Image uploads using ImageKit Account 1.
class AdvertisementImageService {
  final _service = ImageKitAccount1().service;
  
  static const String _folder = 'advertisements/banners/';
  static const String _localProductsFolder = 'advertisements/local_products/';

  /// Uploads a banner image to ImageKit.
  Future<ImageKitUploadResult> uploadBanner({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final safeName = _service.generateFileName(fileName, 'banner');
    return await _service.uploadImage(
      imageBytes: imageBytes,
      fileName: safeName,
      folder: _folder,
      onProgress: onProgress,
    );
  }

  /// Uploads a local product image for ads to ImageKit.
  Future<ImageKitUploadResult> uploadLocalProduct({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final safeName = _service.generateFileName(fileName, 'prod');
    return await _service.uploadImage(
      imageBytes: imageBytes,
      fileName: safeName,
      folder: _localProductsFolder,
      onProgress: onProgress,
    );
  }

  /// Deletes a banner image from ImageKit using its fileId.
  Future<void> deleteBanner(String fileId) async {
    await _service.deleteImage(fileId);
  }
}
