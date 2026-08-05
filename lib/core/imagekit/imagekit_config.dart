class ImageKitConfig {
  final String publicKey;
  final String privateKey;
  final String urlEndpoint;
  final String defaultFolder;
  final String accountName;

  const ImageKitConfig({
    required this.publicKey,
    required this.privateKey,
    required this.urlEndpoint,
    required this.defaultFolder,
    required this.accountName,
  });
}
