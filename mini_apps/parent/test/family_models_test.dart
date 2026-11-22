import 'package:flutter_test/flutter_test.dart';
import 'package:parent/features/family/data/family_models.dart';

void main() {
  test('startsAt UTC từ server được đổi sang giờ máy trước khi hiển thị', () {
    final s = AttendanceSession.fromJson({
      'sessionId': 's1',
      'className': 'Toán 9A',
      'startsAt': '2026-12-15T11:00:00.000Z', // 18:00 giờ VN
      'sessionStatus': 'planned',
      'isMakeup': false,
      'attendanceStatus': null,
    });
    // DateFormat format thẳng các trường của DateTime: còn UTC thì hiện 11:00.
    expect(s.startsAt.isUtc, isFalse);
    expect(s.startsAt.isAtSameMomentAs(DateTime.utc(2026, 12, 15, 11)), isTrue);
    expect(s.startsAt.hour, DateTime.utc(2026, 12, 15, 11).toLocal().hour);
  });
}
