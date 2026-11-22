import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/data/class_models.dart';

void main() {
  const base = ClassInput(
    name: 'A',
    subject: 'B',
    grade: 9,
    location: 'x',
    startDate: '2026-12-14',
  );
  ScheduleRule r(int weekday, String start, [int min = 90]) =>
      ScheduleRule(weekday: weekday, startTime: start, durationMin: min);
  ClassFieldError? err(List<ScheduleRule> rules) =>
      validateClass(base, rules)['rules'];

  test('mỗi thứ một giờ riêng: hợp lệ (US-0.2 AC6)', () {
    expect(err([r(1, '17:30'), r(3, '18:00'), r(5, '17:30', 120)]), isNull);
  });

  test('cùng thứ, không chồng giờ: hợp lệ (2 buổi trong ngày)', () {
    expect(err([r(1, '08:00'), r(1, '09:30')]), isNull);
  });

  test('cùng thứ và chồng giờ: lỗi', () {
    expect(err([r(1, '17:30'), r(1, '18:00')]), ClassFieldError.rulesDuplicate);
    expect(err([r(1, '17:30'), r(1, '17:30')]), ClassFieldError.rulesDuplicate);
  });
}
