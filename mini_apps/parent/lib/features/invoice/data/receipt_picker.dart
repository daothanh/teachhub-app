import 'package:image_picker/image_picker.dart';

import 'receipt_models.dart';

/// Chọn ảnh biên lai từ thư viện ảnh. Trả `null` khi người dùng hủy.
abstract interface class ReceiptPicker {
  Future<ReceiptImage?> pick();
}

/// `image_picker` nén ngay khi chọn (cạnh dài ≤ 2000 px, chất lượng 80) và
/// đổi HEIC sang JPEG, nên ảnh chụp màn hình/ảnh máy ảnh thường còn dưới 1 MB.
/// Dùng PHPicker/Photo Picker của hệ điều hành: không xin quyền camera, không
/// đọc cả thư viện (`requestFullMetadata: false`).
class ImagePickerReceiptPicker implements ReceiptPicker {
  const ImagePickerReceiptPicker();

  @override
  Future<ReceiptImage?> pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final name = file.name.isEmpty ? 'bien-lai.jpg' : file.name;
    return ReceiptImage(
      fileName: name,
      mimeType:
          file.mimeType ?? mimeFromFileName(name) ?? 'application/octet-stream',
      bytes: await file.readAsBytes(),
    );
  }
}
