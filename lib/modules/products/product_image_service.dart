import 'dart:typed_data';
import '../../../core/imagekit/imagekit_models.dart';
import '../../../services/imagekit_service.dart';
import '../../../core/imagekit/image_storage_type.dart';

/// Service for handling Product Image uploads using centralized ImageKitService.
class ProductImageService {
  final _service = ImageKitService();
  
  static const String _folder = 'products/images/';

  /// Uploads a product image to ImageKit.
  Future<ImageKitUploadResult> uploadProductImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _service.uploadImage(
      storageType: ImageStorageType.products,
      imageBytes: imageBytes,
      fileName: fileName,
      folder: _folder,
      onProgress: onProgress,
    );
  }

  /// Deletes a product image from ImageKit using its fileId.
  Future<void> deleteProductImage(String fileId) async {
    await _service.deleteImage(
      storageType: ImageStorageType.products,
      imageFileId: fileId,
    );
  }
}

