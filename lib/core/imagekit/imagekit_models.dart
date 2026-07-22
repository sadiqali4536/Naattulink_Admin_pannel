class ImageKitUploadResult {
  final String imageUrl;
  final String fileId;

  const ImageKitUploadResult({
    required this.imageUrl,
    required this.fileId,
  });

  factory ImageKitUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageKitUploadResult(
      imageUrl: json['url'] as String? ?? '',
      fileId: json['fileId'] as String? ?? '',
    );
  }
}
