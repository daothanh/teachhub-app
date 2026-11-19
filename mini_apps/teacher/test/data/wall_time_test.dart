import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/data/cache/wall_time.dart';

void main() {
  test('wallTime theo offset của tenant, không theo múi giờ máy', () {
    // 18:00+07:00 = 11:00Z.
    expect(wallTime(DateTime.utc(2026, 11, 18, 11), 420), '18:00');
    expect(wallTime(DateTime.utc(2026, 11, 18, 23, 5), 420), '06:05');
    expect(wallTime(DateTime.utc(2026, 11, 18, 11), 0), '11:00');
  });

  test('wallTime dòng cũ không có offset: dùng giờ máy', () {
    final t = DateTime.utc(2026, 11, 18, 11);
    final l = t.toLocal();
    expect(
      wallTime(t, null),
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}',
    );
  });

  test('wallTimeFromIso lấy HH:mm trong chuỗi, chuỗi lạ giữ nguyên', () {
    expect(wallTimeFromIso('2026-12-15T18:00:00+07:00'), '18:00');
    expect(wallTimeFromIso('2026-12-15'), '2026-12-15');
    expect(wallTimeFromIso('2026-12-15T18'), '2026-12-15T18');
  });
}
