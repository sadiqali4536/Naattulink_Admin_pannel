import 'dart:typed_data';
import '../../../core/imagekit/imagekit_account2.dart';
import '../../../core/imagekit/imagekit_models.dart';

/// Service for handling Product Image uploads using ImageKit Account 2.
class ProductImageService {
  final _service = ImageKitAccount2().service;
  
  static const String _folder = 'products/images/';

  /// Uploads a product image to ImageKit.
  Future<ImageKitUploadResult> uploadProductImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final safeName = _service.generateFileName(fileName, 'product');
    return await _service.uploadImage(
      imageBytes: imageBytes,
      fileName: safeName,
      folder: _folder,
      onProgress: onProgress,
    );
  }

  /// Deletes a product image from ImageKit using its fileId.
  Future<void> deleteProductImage(String fileId) async {
    await _service.deleteImage(fileId);
  }
}
