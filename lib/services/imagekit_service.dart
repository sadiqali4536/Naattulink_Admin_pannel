import 'dart:developer';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/imagekit/image_storage_type.dart';
import '../core/imagekit/imagekit_config_manager.dart';
import '../core/imagekit/imagekit_base_service.dart';
import '../core/imagekit/imagekit_models.dart';
import '../core/imagekit/imagekit_exceptions.dart';

class ImageKitService {
  // Singleton pattern
  static final ImageKitService _instance = ImageKitService._internal();
  factory ImageKitService() => _instance;
  ImageKitService._internal();

  /// Uploads an image to the appropriate ImageKit account based on [storageType].
  Future<ImageKitUploadResult> uploadImage({
    required ImageStorageType storageType,
    required Uint8List imageBytes,
    required String fileName,
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    final config = ImageKitConfigManager.getConfig(storageType);
    final service = ImageKitBaseService(
      publicKey: config.publicKey,
      privateKey: config.privateKey,
      urlEndpoint: config.urlEndpoint,
    );

    final uploadFolder = folder ?? config.defaultFolder;
    final safeName = service.generateFileName(fileName, storageType.name);

    try {
      final result = await service.uploadImage(
        imageBytes: imageBytes,
        fileName: safeName,
        folder: uploadFolder,
        onProgress: onProgress,
      );

      _logOperation(
        operation: 'UPLOAD',
        storageType: storageType,
        accountName: config.accountName,
        folder: uploadFolder,
        fileId: result.imageFileId,
        imageUrl: result.imageUrl,
        status: 'SUCCESS',
      );

      return result;
    } catch (e) {
      _logOperation(
        operation: 'UPLOAD',
        storageType: storageType,
        accountName: config.accountName,
        folder: uploadFolder,
        status: 'FAILED',
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Deletes an image from the appropriate ImageKit account based on [storageType].
  Future<void> deleteImage({
    required ImageStorageType storageType,
    required String imageFileId,
    int retryCount = 0,
  }) async {
    final config = ImageKitConfigManager.getConfig(storageType);
    
    try {
      final authHeader = 'Basic ' + base64Encode(utf8.encode('${config.privateKey}:'));
      final targetUrl = 'https://api.imagekit.io/v1/files/$imageFileId';
      
      // Use corsproxy.io which is generally more reliable than thingproxy
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(targetUrl)}';

      final response = await http.delete(
        Uri.parse(proxyUrl),
        headers: {
          'Authorization': authHeader,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete image: ${response.body}');
      }

      _logOperation(
        operation: 'DELETE',
        storageType: storageType,
        accountName: config.accountName,
        fileId: imageFileId,
        status: 'SUCCESS',
      );
    } catch (e) {
      _logOperation(
        operation: 'DELETE',
        storageType: storageType,
        accountName: config.accountName,
        fileId: imageFileId,
        status: 'FAILED',
        error: e.toString(),
      );

      if (retryCount < 2) {
        log(
          'Retrying delete operation for file $imageFileId... (Attempt ${retryCount + 1})',
        );
        await Future.delayed(const Duration(seconds: 2));
        return deleteImage(
          storageType: storageType,
          imageFileId: imageFileId,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    }
  }

  void _logOperation({
    required String operation,
    required ImageStorageType storageType,
    required String accountName,
    String? folder,
    String? fileId,
    String? imageUrl,
    String? documentId,
    required String status,
    String? error,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    log('''
================= IMAGEKIT $operation =================
Timestamp: $timestamp
Storage Type: ${storageType.name}
Account: $accountName
${folder != null ? 'Folder: $folder\n' : ''}${fileId != null ? 'File ID: $fileId\n' : ''}${imageUrl != null ? 'Image URL: $imageUrl\n' : ''}${documentId != null ? 'Document ID: $documentId\n' : ''}Status: $status
${error != null ? 'Error: $error\n' : ''}=======================================================
''');
  }
}
