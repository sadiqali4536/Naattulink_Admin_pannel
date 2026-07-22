import 'imagekit_base_service.dart';

/// Configuration for ImageKit Account 1
/// Used ONLY for Advertisement images.
class ImageKitAccount1 {
  // Singleton pattern
  static final ImageKitAccount1 _instance = ImageKitAccount1._internal();
  factory ImageKitAccount1() => _instance;
  
  late final ImageKitBaseService service;

  ImageKitAccount1._internal() {
    service = const ImageKitBaseService(
      // Keep this in admin code only — never expose in a public mobile app.
      publicKey: '', // Not required for server-side REST API upload
      privateKey: 'private_KgiMaSuYgh1Xx4Q8ZBOydkQdFx0=',
      urlEndpoint: 'https://ik.imagekit.io/naattulink',
    );
  }
}
