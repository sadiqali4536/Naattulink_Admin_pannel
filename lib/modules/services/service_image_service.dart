import 'dart:typed_data';
import '../../../core/imagekit/imagekit_account2.dart';
import '../../../core/imagekit/imagekit_models.dart';

/// Service for handling Service Image uploads using ImageKit Account 2.
class ServiceImageService {
  final _service = ImageKitAccount2().service;
  
  static const String _folder = 'services/service_images/';
  static const String _categoryFolder = 'services/categories/';

  /// Uploads a service image to ImageKit.
  Future<ImageKitUploadResult> uploadServiceImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final safeName = _service.generateFileName(fileName, 'service');
    return await _service.uploadImage(
      imageBytes: imageBytes,
      fileName: safeName,
      folder: _folder,
      onProgress: onProgress,
    );
  }

  /// Uploads a category image to ImageKit.
  Future<ImageKitUploadResult> uploadCategoryImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final safeName = _service.generateFileName(fileName, 'category');
    return await _service.uploadImage(
      imageBytes: imageBytes,
      fileName: safeName,
      folder: _categoryFolder,
      onProgress: onProgress,
    );
  }

  /// Deletes a service image from ImageKit using its fileId.
  Future<void> deleteServiceImage(String fileId) async {
    await _service.deleteImage(fileId);
  }

  /// Deletes a category image from ImageKit using its fileId.
  Future<void> deleteCategoryImage(String fileId) async {
    await _service.deleteImage(fileId);
  }
}
