import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  img.Image canvas = img.Image(width: 1080, height: 600);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  print('Canvas created: ${canvas.width}x${canvas.height}');
}
