import 'image_storage_type.dart';
import 'imagekit_config.dart';

class ImageKitConfigManager {
  static ImageKitConfig getConfig(ImageStorageType storageType) {
    switch (storageType) {
      case ImageStorageType.banners:
        return const ImageKitConfig(
          publicKey: 'public_lCHQ34M0MLPZC10qeJYNCM8rQv0=',
          privateKey: 'private_KgiMaSuYgh1Xx4Q8ZBOydkQdFx0=',
          urlEndpoint: 'https://ik.imagekit.io/naattulink',
          defaultFolder: 'advertisements/banners/',
          accountName: 'Account 1 (Advertisements)',
        );
      case ImageStorageType.services:
        return const ImageKitConfig(
          publicKey: 'public_tllKZT9Hfbe4KFXz9S9T5HYWvzU=',
          privateKey: 'private_5R9DaVHXj9Ysxuf41h1BaOV4xe0=',
          urlEndpoint: 'https://ik.imagekit.io/mgk8josdiz',
          defaultFolder: 'services/',
          accountName: 'Account 2 (Services & Products)',
        );
      case ImageStorageType.products:
        return const ImageKitConfig(
          publicKey: 'public_t88OIct944WyyAoX5I48PjKkiBc=',
          privateKey: 'private_7S6xqXtVuzxoWEOy68+33E9xdA0=',
          urlEndpoint: 'https://ik.imagekit.io/cupjfca3p',
          defaultFolder: 'products/images/',
          accountName: 'Account 3 (Products)',
        );
      case ImageStorageType.workers:
        return const ImageKitConfig(
          publicKey: 'account4_public_key',
          privateKey: 'account4_private_key',
          urlEndpoint: 'https://ik.imagekit.io/account4',
          defaultFolder: 'workers/',
          accountName: 'Account 4 (Workers)',
        );
    }
  }
}
