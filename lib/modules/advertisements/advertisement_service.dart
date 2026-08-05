import 'dart:typed_data';
import '../../../core/imagekit/imagekit_models.dart';
import '../../../services/imagekit_service.dart';
import '../../../core/imagekit/image_storage_type.dart';

/// Service for handling Advertisement Image uploads using centralized ImageKitService.
class AdvertisementImageService {
  final _service = ImageKitService();
  
  static const String _folder = 'advertisements/banners/';
  static const String _localProductsFolder = 'advertisements/local_products/';

  /// Uploads a banner image to ImageKit.
  Future<ImageKitUploadResult> uploadBanner({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _service.uploadImage(
      storageType: ImageStorageType.banners,
      imageBytes: imageBytes,
      fileName: fileName,
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
    return await _service.uploadImage(
      storageType: ImageStorageType.banners,
      imageBytes: imageBytes,
      fileName: fileName,
      folder: _localProductsFolder,
      onProgress: onProgress,
    );
  }

  /// Deletes a banner image from ImageKit using its fileId.
  Future<void> deleteBanner(String imageFileId) async {
    await _service.deleteImage(
      storageType: ImageStorageType.banners, 
      imageFileId: imageFileId,
    );
  }
}

