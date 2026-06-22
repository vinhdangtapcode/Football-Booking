import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Nén ảnh gốc và chuyển đổi sang định dạng WebP chất lượng tối ưu (chạy trên client)
  static Future<File?> compressToWebp(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.webp';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75, // Chất lượng 75% tối ưu cho hiển thị di động và web
        format: CompressFormat.webp,
        minWidth: 1080,  // Giới hạn chiều rộng tối đa là 1080px
        minHeight: 1080, // Giới hạn chiều cao tối đa là 1080px
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      print('Lỗi khi nén ảnh sang WebP: $e');
    }
    return null;
  }
}
