import 'imagekit_base_service.dart';

/// Configuration for ImageKit Account 2
/// Used ONLY for Services and Products images.
class ImageKitAccount2 {
  // Singleton pattern
  static final ImageKitAccount2 _instance = ImageKitAccount2._internal();
  factory ImageKitAccount2() => _instance;
  
  late final ImageKitBaseService service;

  ImageKitAccount2._internal() {
    service = const ImageKitBaseService(
      // Keep this in admin code only — never expose in a public mobile app.
      publicKey: 'public_tllKZT9Hfbe4KFXz9S9T5HYWvzU=', 
      privateKey: 'private_5R9DaVHXj9Ysxuf41h1BaOV4xe0=',
      urlEndpoint: 'https://ik.imagekit.io/mgk8josdiz',
    );
  }
}
