import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/onboarding/data/onboarding_models.dart';
import 'package:teacher/features/students/data/student_models.dart';

/// Đối chiếu model T07/T02 với `contracts/openapi.json` (bản chép từ backend,
/// cập nhật bằng `dart run tool/sync_openapi.dart` trong packages/teachhub_shared).
final _openapi =
    jsonDecode(
          File(
            '../../packages/teachhub_shared/contracts/openapi.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final _schemas =
    (_openapi['components'] as Map)['schemas'] as Map<String, dynamic>;

Map<String, dynamic> _props(Map schema) =>
    (schema['properties'] as Map).cast<String, dynamic>();

Map<String, dynamic> _body(String path, String method) =>
    ((((_openapi['paths'] as Map)[path] as Map)[method] as Map)['requestBody']
            as Map)['content']['application/json']['schema']
        as Map<String, dynamic>;

void main() {
  test('StudentCandidate đọc đủ trường của schema và nhận dob/school null', () {
    final props = _props(_schemas['StudentCandidate'] as Map).keys.toSet();
    expect(props, {'id', 'fullName', 'dob', 'school'});
    final c = StudentCandidate.fromJson({
      'id': 'a',
      'fullName': 'Minh Anh',
      'dob': null,
      'school': null,
    });
    expect(c.dob, isNull);
    expect(c.school, isNull);
  });

  test('Student: id và fullName có trong schema Student', () {
    final student = _schemas['Student'] as Map;
    expect(_props(student).keys, containsAll(['id', 'fullName']));
    expect(Student.fromJson({'id': 'a', 'fullName': 'B'}).fullName, 'B');
  });

  test('thân POST /students: mọi khóa app gửi đều có trong hợp đồng', () {
    final body = _body('/v1/students', 'post');
    final draft = StudentDraft(
      fullName: 'Minh Anh',
      dob: DateTime(2011, 5, 20),
      school: 'THCS',
      note: 'n',
      guardians: const [GuardianDraft(fullName: 'Hải', phone: '0912345678')],
    );
    final json = draft.toJson(confirmNew: true);
    expect(json['dob'], '2011-05-20');
    expect(_props(body).keys, containsAll(json.keys));
    expect(body['required'], ['fullName']);
    final guardian = (_props(body)['guardians'] as Map)['items'] as Map;
    expect(
      _props(guardian).keys,
      containsAll(draft.guardians.first.toJson().keys),
    );
    expect((_props(body)['guardians'] as Map)['maxItems'], 2);
    // `id` của phụ huynh nghĩa là "cập nhật": tạo mới thì không được gửi.
    expect(draft.guardians.first.toJson().containsKey('id'), isFalse);
  });

  test('chỉ họ tên: thân request không có khóa thừa', () {
    expect(const StudentDraft(fullName: 'A').toJson(), {'fullName': 'A'});
  });

  test('Onboarding: enum bước và trạng thái khớp hợp đồng', () {
    final onboarding = _schemas['Onboarding'] as Map;
    final item = (_props(onboarding)['steps'] as Map)['items'] as Map;
    expect(
      _props(item)['step']['enum'],
      OnboardingStep.values.map((s) => s.wire),
    );
    expect(
      _props(item)['status']['enum'],
      OnboardingStatus.values.map((s) => s.name),
    );
  });

  test('Onboarding.fromJson đọc steps và currentStep (kể cả null)', () {
    final example = (_schemas['Onboarding'] as Map)['example'] as Map;
    final parsed = Onboarding.fromJson(example.cast<String, dynamic>());
    expect(parsed.currentStep, OnboardingStep.addStudents);
    expect(parsed.handled, 1);
    expect(
      Onboarding.fromJson({
        'steps': example['steps'],
        'currentStep': null,
      }).currentStep,
      isNull,
    );
  });

  test('PATCH step: status chỉ done|skipped; bước 1 không bỏ qua', () {
    final body = _body('/v1/onboarding/steps/{step}', 'patch');
    expect(_props(body)['status']['enum'], ['done', 'skipped']);
    expect(OnboardingStep.createClass.skippable, isFalse);
    expect(
      OnboardingStep.values.where((s) => s != OnboardingStep.createClass),
      everyElement(predicate<OnboardingStep>((s) => s.skippable)),
    );
  });

  test('Onboarding: bước và trạng thái lạ từ server mới hơn không làm ném', () {
    final parsed = Onboarding.fromJson({
      'steps': [
        {'step': 'create_class', 'status': 'done'},
        {'step': 'add_students', 'status': 'pending'},
        {'step': 'new_step_v2', 'status': 'pending'},
        {'step': 'set_schedule', 'status': 'weird'},
      ],
      'currentStep': 'new_step_v2',
    });
    expect(parsed.steps.length, 3);
    expect(parsed.steps[OnboardingStep.setSchedule], OnboardingStatus.pending);
    expect(parsed.currentStep, OnboardingStep.addStudents);
  });
}
