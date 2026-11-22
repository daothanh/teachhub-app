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

final _validPhone = RegExp(r'^\+?[0-9]{8,15}$');

/// Số đầu tiên hợp lệ sau chuẩn hóa; không có thì số đầu tiên.
String? _bestPhone(Iterable<String> numbers) {
  for (final n in numbers) {
    if (_validPhone.hasMatch(normalizePhone(n) ?? '')) return n;
  }
  return numbers.firstOrNull;
}

/// Bọc plugin danh bạ để test không cần native.
abstract class ContactsService {
  /// Chỉ gọi khi người dùng bấm "Thêm từ danh bạ".
  Future<ContactsAccess> requestAccess();
  Future<List<PickableContact>> load();
  Future<void> openSettings();

  /// Bộ chọn liên hệ của hệ điều hành: các số của liên hệ được chọn, `null`
  /// khi người dùng hủy. Gọi sau [requestAccess] (Android cần quyền để đọc số).
  Future<List<String>?> pickPhones();
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
            phone: _bestPhone(c.phones.map((p) => p.number)),
          ),
    ];
  }

  @override
  Future<void> openSettings() => fc.FlutterContacts.permissions.openSettings();

  @override
  Future<List<String>?> pickPhones() async {
    final c = await fc.FlutterContacts.native.showPicker(
      properties: {fc.ContactProperty.phone},
    );
    return c?.phones.map((p) => p.number).toList();
  }
}

/// SĐT trong danh bạ → dạng nhập ở form: bỏ dấu cách/chấm/gạch/ngoặc, `+84…`,
/// `0084…` và `84…` thành `0…` (bỏ cả số 0 thừa sau mã nước, vd `+84(0)912…`);
/// số quốc tế khác giữ `+`. Trả `null` khi trống.
String? normalizePhone(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  var intl = raw.trimLeft().startsWith('+');
  if (!intl && digits.startsWith('00')) {
    intl = true;
    digits = digits.substring(2);
  }
  if (digits.startsWith('84') && (intl || digits.length == 11)) {
    var rest = digits.substring(2);
    if (rest.startsWith('0')) rest = rest.substring(1);
    return '0$rest';
  }
  return intl ? '+$digits' : digits;
}
