import 'dart:typed_data';
import '../../../core/imagekit/imagekit_account3.dart';
import '../../../core/imagekit/imagekit_models.dart';

/// Service for handling Worker Profile Image uploads using ImageKit Account 3.
class WorkerImageService {
  final _service = ImageKitAccount3().service;
  
  static const String _folder = 'workers/profile_images/';

  /// Uploads a worker profile image to ImageKit.
  Future<ImageKitUploadResult> uploadProfileImage({
    required Uint8List imageBytes,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final safeName = _service.generateFileName(fileName, 'profile');
    return await _service.uploadImage(
      imageBytes: imageBytes,
      fileName: safeName,
      folder: _folder,
      onProgress: onProgress,
    );
  }

  /// Deletes a worker profile image from ImageKit using its fileId.
  Future<void> deleteProfileImage(String fileId) async {
    await _service.deleteImage(fileId);
  }
}
