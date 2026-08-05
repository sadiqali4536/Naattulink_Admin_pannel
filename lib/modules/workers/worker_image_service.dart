import 'dart:typed_data';
import '../../../core/imagekit/imagekit_models.dart';
import '../../../services/imagekit_service.dart';
import '../../../core/imagekit/image_storage_type.dart';

/// Service for handling Worker Profile Image uploads using centralized ImageKitService.
class WorkerImageService {
  final _service = ImageKitService();

  static const String _folder = 'workers/profile_images/';

  /// Uploads a worker profile image to ImageKit.
  Future<ImageKitUploadResult> uploadProfileImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    return await _service.uploadImage(
      storageType: ImageStorageType.workers,
      imageBytes: imageBytes,
      fileName: fileName,
      folder: _folder,
      onProgress: onProgress,
    );
  }

  /// Deletes a worker profile image from ImageKit using its fileId.
  Future<void> deleteProfileImage(String fileId) async {
    await _service.deleteImage(
      storageType: ImageStorageType.workers,
      imageFileId: fileId,
    );
  }
}
