import 'imagekit_base_service.dart';

/// Configuration for ImageKit Account 3
/// Used ONLY for Worker Profile Images.
class ImageKitAccount3 {
  // Singleton pattern
  static final ImageKitAccount3 _instance = ImageKitAccount3._internal();
  factory ImageKitAccount3() => _instance;
  
  late final ImageKitBaseService service;

  ImageKitAccount3._internal() {
    service = const ImageKitBaseService(
      // TODO: Replace with Account 3 actual credentials
      publicKey: 'account3_public_key', 
      privateKey: 'account3_private_key',
      urlEndpoint: 'https://ik.imagekit.io/account3',
    );
  }
}
