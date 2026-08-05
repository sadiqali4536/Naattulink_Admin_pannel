class ImageKitUploadResult {
  final String imageUrl;
  final String imageFileId;

  const ImageKitUploadResult({
    required this.imageUrl,
    required this.imageFileId,
  });

  factory ImageKitUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageKitUploadResult(
      imageUrl: json['url'] as String? ?? '',
      imageFileId: json['fileId'] as String? ?? '',
    );
  }
}
