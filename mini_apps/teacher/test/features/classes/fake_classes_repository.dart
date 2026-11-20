import 'dart:async';

import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';

TeachClass sampleClass({
  String id = 'c1',
  String name = 'Toán 9A',
  ClassStatus status = ClassStatus.active,
  List<ScheduleRule> rules = const [],
  int enrolled = 0,
}) => TeachClass(
  id: id,
  name: name,
  subject: 'Toán',
  grade: 9,
  mode: ClassMode.offline,
  location: 'Nhà riêng',
  capacity: 20,
  startDate: '2026-12-14',
  endDate: null,
  status: status,
  enrolledCount: enrolled,
  scheduleRules: rules,
  createdAt: '2026-12-01T00:00:00.000Z',
);

ClassSession sampleSession({
  String id = 'x1',
  SessionStatus status = SessionStatus.planned,
  bool isMakeup = false,
  String? makeupOf,
  String? cancelReason,
  String date = '2026-12-15',
}) => ClassSession(
  id: id,
  classId: 'c1',
  className: 'Toán 9A',
  sessionDate: date,
  startsAt: '${date}T18:00:00+07:00',
  endsAt: '${date}T19:30:00+07:00',
  status: status,
  isMakeup: isMakeup,
  makeupOf: makeupOf,
  cancelReason: cancelReason,
);

ApiException validationError(Map<String, List<String>> errors) => ApiException(
  code: ApiErrorCode.validationFailed,
  wireCode: 'VALIDATION_FAILED',
  status: 422,
  fieldErrors: errors,
);

ApiException apiError(ApiErrorCode c) =>
    ApiException(code: c, wireCode: c.wire, status: c.http);

/// Bản giả: mỗi thao tác chạy `onX` nếu có, không thì trả giá trị mặc định.
class FakeClassesRepository implements ClassesRepository {
  final calls = <String>[];

  /// Khóa idempotency của từng lệnh ghi, theo thứ tự gọi.
  final keys = <String?>[];
  List<TeachClass> active = [];
  List<TeachClass> archived = [];
  TeachClass? current;
  List<RosterEntry> rosterItems = [];
  List<ClassSession> sessionItems = [];
  List<StudentSummary> students = [];
  Object? listError;

  /// Giả lập còn trang sau: `total` lớn hơn số mục; lỗi chỉ ở trang này.
  int? listTotal;
  int? listErrorPage;
  Completer<void>? listGate;
  Object? getError;
  Object? createError;
  Object? updateError;
  Object? archiveError;
  Object? putRulesError;
  Object? enrollError;
  Object? sessionsError;
  bool alreadyEnrolled = false;
  ClassInput? lastInput;
  List<ScheduleRule>? lastRules;
  String? lastQuery;
  ({String from, String to, String? classId})? lastSessionRange;

  @override
  Future<Paginated<TeachClass>> list({
    ClassStatus status = ClassStatus.active,
    int page = 1,
  }) async {
    calls.add('list:${status.name}:$page');
    await listGate?.future;
    if (listError != null || listErrorPage == page) {
      throw listError ?? const ApiException.network();
    }
    final items = status == ClassStatus.active ? active : archived;
    return Paginated(
      items: items,
      total: listTotal ?? items.length,
      page: page,
      pageSize: 20,
    );
  }

  @override
  Future<TeachClass> get(String id) async {
    calls.add('get:$id');
    if (getError != null) throw getError!;
    return current ?? sampleClass(id: id);
  }

  @override
  Future<ClassCreated> create(
    ClassInput input, {
    String? idempotencyKey,
  }) async {
    calls.add('create');
    keys.add(idempotencyKey);
    lastInput = input;
    if (createError != null) throw createError!;
    final c = sampleClass(id: 'new', name: input.name);
    current = c;
    return ClassCreated(c, const []);
  }

  @override
  Future<TeachClass> update(
    String id,
    ClassInput input, {
    String? idempotencyKey,
  }) async {
    calls.add('update:$id');
    keys.add(idempotencyKey);
    lastInput = input;
    if (updateError != null) throw updateError!;
    return current = sampleClass(id: id, name: input.name);
  }

  @override
  Future<TeachClass> archive(String id, {String? idempotencyKey}) async {
    calls.add('archive:$id');
    keys.add(idempotencyKey);
    if (archiveError != null) throw archiveError!;
    return sampleClass(id: id, status: ClassStatus.archived);
  }

  /// Lỗi/kết quả cho 3 lệnh buổi học; `calls` ghi `reschedule:id:startsAt`…
  Object? sessionActionError;
  ClassSession? sessionActionResult;

  Future<ClassSession> _sessionAction(
    String call,
    String id,
    String? key,
  ) async {
    calls.add(call);
    keys.add(key);
    if (sessionActionError != null) throw sessionActionError!;
    return sessionActionResult ??
        sessionItems.firstWhere(
          (s) => s.id == id,
          orElse: () => sampleSession(),
        );
  }

  @override
  Future<ClassSession> reschedule(
    String sessionId, {
    required String startsAt,
    String? reason,
    String? idempotencyKey,
  }) => _sessionAction(
    'reschedule:$sessionId:$startsAt:${reason ?? ''}',
    sessionId,
    idempotencyKey,
  );

  @override
  Future<ClassSession> cancel(
    String sessionId, {
    String? reason,
    String? idempotencyKey,
  }) => _sessionAction(
    'cancel:$sessionId:${reason ?? ''}',
    sessionId,
    idempotencyKey,
  );

  @override
  Future<ClassSession> makeup(
    String sessionId, {
    required String startsAt,
    String? idempotencyKey,
  }) =>
      _sessionAction('makeup:$sessionId:$startsAt', sessionId, idempotencyKey);

  @override
  Future<List<RosterEntry>> roster(String id) async => rosterItems;

  @override
  Future<EnrollResult> enroll(
    String classId,
    String studentId, {
    String? idempotencyKey,
  }) async {
    calls.add('enroll:$classId:$studentId');
    keys.add(idempotencyKey);
    if (enrollError != null) throw enrollError!;
    return EnrollResult(
      Enrollment(
        id: 'e1',
        classId: classId,
        studentId: studentId,
        joinedOn: '2026-12-14',
      ),
      alreadyEnrolled: alreadyEnrolled,
    );
  }

  @override
  Future<Paginated<StudentSummary>> searchStudents(String q) async {
    calls.add('search:$q');
    lastQuery = q;
    return Paginated(
      items: students,
      total: students.length,
      page: 1,
      pageSize: 20,
    );
  }

  @override
  Future<ScheduleRulesResult> putRules(
    String classId,
    List<ScheduleRule> rules, {
    String? idempotencyKey,
  }) async {
    calls.add('putRules:$classId');
    keys.add(idempotencyKey);
    lastRules = rules;
    if (putRulesError != null) throw putRulesError!;
    return ScheduleRulesResult(
      rules: rules,
      sessionsGenerated: rules.length * 8,
      sessionsRemoved: 0,
    );
  }

  @override
  Future<List<ClassSession>> sessions({
    required String from,
    required String to,
    String? classId,
  }) async {
    calls.add('sessions');
    lastSessionRange = (from: from, to: to, classId: classId);
    if (sessionsError != null) throw sessionsError!;
    return sessionItems;
  }
}
