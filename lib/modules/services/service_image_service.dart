import 'dart:typed_data';
import '../../../core/imagekit/imagekit_models.dart';
import '../../../services/imagekit_service.dart';
import '../../../core/imagekit/image_storage_type.dart';

/// Service for handling Service Image uploads using centralized ImageKitService.
class ServiceImageService {
  final _service = ImageKitService();
  
  static const String _folder = 'services/service_images/';
  static const String _categoryFolder = 'services/categories/';

  /// Uploads a service image to ImageKit.
  Future<ImageKitUploadResult> uploadServiceImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _service.uploadImage(
      storageType: ImageStorageType.services,
      imageBytes: imageBytes,
      fileName: fileName,
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
    return await _service.uploadImage(
      storageType: ImageStorageType.services,
      imageBytes: imageBytes,
      fileName: fileName,
      folder: _categoryFolder,
      onProgress: onProgress,
    );
  }

  /// Deletes a service image from ImageKit using its fileId.
  Future<void> deleteServiceImage(String fileId) async {
    await _service.deleteImage(
      storageType: ImageStorageType.services,
      imageFileId: fileId,
    );
  }

  /// Deletes a category image from ImageKit using its fileId.
  Future<void> deleteCategoryImage(String fileId) async {
    await _service.deleteImage(
      storageType: ImageStorageType.services,
      imageFileId: fileId,
    );
  }

  /// Replaces a service image by deleting the old one (if fileId provided) and uploading a new one.
  Future<ImageKitUploadResult> replaceServiceImage({
    required String? oldImageFileId,
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    if (oldImageFileId != null && oldImageFileId.isNotEmpty) {
      try {
        await deleteServiceImage(oldImageFileId);
      } catch (e) {
        // Ignore deletion errors to ensure upload still proceeds
        print("Error deleting old service image: $e");
      }
    }
    
    return await uploadServiceImage(
      imageBytes: imageBytes,
      fileName: fileName,
      onProgress: onProgress,
    );
  }
}

