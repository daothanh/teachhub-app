import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

enum ContactsAccess { granted, denied, permanentlyDenied }

/// Liên hệ đủ dùng để thành học viên nháp: tên và SĐT đầu tiên (nếu có).
class PickableContact extends Equatable {
  const PickableContact({required this.id, required this.name, this.phone});

  final String id;
  final String name;
  final String? phone;

  @override
  List<Object?> get props => [id, name, phone];
}

/// Bọc plugin danh bạ để test không cần native.
abstract class ContactsService {
  /// Chỉ gọi khi người dùng bấm "Thêm từ danh bạ".
  Future<ContactsAccess> requestAccess();
  Future<List<PickableContact>> load();
  Future<void> openSettings();
}

class DeviceContactsService implements ContactsService {
  @override
  Future<ContactsAccess> requestAccess() async {
    final status = await fc.FlutterContacts.permissions.request(
      fc.PermissionType.read,
    );
    return switch (status) {
      fc.PermissionStatus.granted ||
      fc.PermissionStatus.limited => ContactsAccess.granted,
      // iOS không hỏi lại sau lần từ chối đầu, nên `restricted` cũng chỉ còn Cài đặt.
      fc.PermissionStatus.permanentlyDenied ||
      fc.PermissionStatus.restricted => ContactsAccess.permanentlyDenied,
      _ => ContactsAccess.denied,
    };
  }

  @override
  Future<List<PickableContact>> load() async {
    final all = await fc.FlutterContacts.getAll(
      properties: {fc.ContactProperty.phone},
    );
    return [
      for (final c in all)
        if ((c.id ?? '').isNotEmpty && (c.displayName ?? '').trim().isNotEmpty)
          PickableContact(
            id: c.id!,
            name: c.displayName!.trim(),
            phone: c.phones.firstOrNull?.number,
          ),
    ];
  }

  @override
  Future<void> openSettings() => fc.FlutterContacts.permissions.openSettings();
}

/// SĐT trong danh bạ → dạng nhập ở form: bỏ dấu cách/chấm/gạch, `+84…` và
/// `84…` thành `0…`; số quốc tế khác giữ `+`. Trả `null` khi trống.
String? normalizePhone(String? raw) {
  if (raw == null) return null;
  final hasPlus = raw.trimLeft().startsWith('+');
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('84') && (hasPlus || digits.length == 11)) {
    return '0${digits.substring(2)}';
  }
  return hasPlus ? '+$digits' : digits;
}
