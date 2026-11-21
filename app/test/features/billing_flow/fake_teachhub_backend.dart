// S5-FL-08, S6-FL-01/02: backend giả có trạng thái, dùng chung cho giáo viên và phụ huynh.
// Cắm vào `Dio.httpClientAdapter`, không mạng thật. Mô phỏng phần liên quan tới
// luồng học phí của hợp đồng Sprint 5: điểm danh → bản nháp của kỳ → điều chỉnh →
// chốt & gửi → `/family/invoices`. Phản hồi (và thân request) được đối chiếu với
// `contracts/openapi.json` nên lệch hợp đồng là đỏ ngay ở đây.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const _contractPath = '../packages/teachhub_shared/contracts/openapi.json';

/// Hợp đồng đọc từ repo; `null` khi chạy trên máy thật (không có file) thì bỏ
/// qua bước đối chiếu, vẫn chạy được kịch bản.
final Map<String, dynamic>? _openapi = File(_contractPath).existsSync()
    ? jsonDecode(File(_contractPath).readAsStringSync()) as Map<String, dynamic>
    : null;

class FakeTeachHubBackend implements HttpClientAdapter {
  FakeTeachHubBackend({required this.now});

  /// Giờ của server giả: kỳ thu, hạn đóng, hạn sửa điểm danh và mọi dấu thời gian
  /// tính từ đây, cố định để kịch bản không phụ thuộc ngày/giờ chạy.
  final DateTime now;

  static const className = 'Toán 9A';
  static const teacherName = 'Cô Lan';
  static const feePerSession = 150000;

  static String uid(int n) =>
      '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

  static final sessionId = uid(10);
  static final classId = uid(11);
  static final periodId = uid(12);

  /// Kỳ liền sau (tháng kế tiếp), chỉ có khi kịch bản gọi [seedNextPeriod].
  static final periodId2 = uid(13);
  static final minhAnh = (id: uid(1), name: 'Nguyễn Minh Anh');
  static final baoChau = (id: uid(2), name: 'Trần Bảo Châu');
  final _students = [minhAnh, baoChau];

  /// Tài khoản nhận tiền (chụp vào hóa đơn lúc chốt); `null` = chưa có.
  Map<String, Object?>? payout;

  /// Mã hóa đơn cấp lần lượt (Crockford, đúng mẫu `TH-xxxxxx` của hợp đồng).
  final _codes = ['25K7Q9', '26M8R2', '27N9S3'];

  /// Học phí tháng (dòng `monthly`) của kỳ sau theo học viên; học viên không có
  /// khoản nào thì không có hóa đơn kỳ sau (US-7.1, D5).
  final _charges2 = <String, int>{};

  /// Mở kỳ sau với khoản học phí tháng của [studentId] (VND).
  void seedNextPeriod(String studentId, int amount) =>
      _charges2[studentId] = amount;

  /// Mọi request đã nhận: `METHOD /path`, đúng thứ tự.
  final requests = <String>[];

  /// Điểm danh đã đồng bộ lên server: học viên → (trạng thái, ghi chú, lúc ghi).
  final _attendance = <String, ({String status, String? note, String at})>{};
  final _adjustments = <String, List<Map<String, Object?>>>{};
  final _issued = <String, Map<String, Object?>>{};
  final _issueReplay = <String, Map<String, Object?>>{};
  final _syncReplay = <String, Map<String, Object?>>{};

  /// Thanh toán theo hóa đơn, cũ trước (phản hồi đảo lại: mới trước).
  final _payments = <String, List<Map<String, Object?>>>{};
  final _payReplay = <String, (int, Map<String, Object?>)>{};
  int _paymentSeq = 0;

  /// Số lần `POST …/payments` thật sự chạy (phát lại theo khóa không tính) và
  /// các khóa nhận được.
  int payExecutions = 0;
  final payKeys = <String>[];

  /// Ghi thanh toán xong nhưng phản hồi mất trên đường về (lỗi mạng), một lần.
  bool dropNextPayResponse = false;

  /// Ghi thanh toán ngay trên server, như một thiết bị khác vừa làm.
  void recordPaymentNow(
    String studentId,
    int amount, {
    String method = 'cash',
  }) => _recordPayment(_invoiceId(studentId), {
    'amount': amount,
    'method': method,
  }, 'seed-${_payReplay.length}');

  /// Thanh toán còn hiệu lực của hóa đơn.
  List<Map<String, Object?>> activePaymentsOf(String invoiceId) => [
    for (final p in _payments[invoiceId] ?? const <Map<String, Object?>>[])
      if (p['voidedAt'] == null) p,
  ];

  /// Ngày của buổi học. Màn "Hôm nay" của teacher lấy ngày từ đồng hồ máy
  /// (`TodayCubit` không có chỗ tiêm), nên buổi được xếp vào đúng ngày app hỏi
  /// ở `GET /sessions?from=`; mặc định là ngày của [now].
  late String sessionDate = _isoDate(now);

  /// Số lần `issue` thật sự chạy (phát lại theo khóa không tính) và các khóa nhận được.
  int issueExecutions = 0;
  final issueKeys = <String>[];

  /// Áp dụng `issue` xong nhưng phản hồi mất trên đường về (lỗi mạng), một lần.
  bool dropNextIssueResponse = false;

  /// Số lần tới `issue` trả 409 `CONFLICT_STALE` mà không chạy gì (kết quả đã
  /// lưu quá hạn phát lại).
  int staleIssues = 0;

  /// Số lần tới `GET /billing-periods/{id}` mất mạng.
  int failPeriodGets = 0;
  String get _month => '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

  /// Số buổi đã ghi cho học viên, để test đối chiếu.
  String? attendanceOf(String studentId) => _attendance[studentId]?.status;

  /// Điểm danh đã có sẵn trên server (kịch bản không đi qua màn điểm danh).
  void recordAttendance(String studentId, String status) =>
      _attendance[studentId] = (
        status: status,
        note: null,
        at: now.toUtc().toIso8601String(),
      );

  /// Chốt tất cả ngay trên server, như một thiết bị khác vừa làm.
  void issueAllNow() {
    issueExecutions++;
    _issue(null);
  }

  /// Hóa đơn đã chốt của học viên (bản server giữ), `null` nếu chưa chốt.
  Map<String, Object?>? issuedInvoiceOf(String studentId) =>
      _issued[_invoiceId(studentId)];

  /// Hóa đơn kỳ sau đã chốt của học viên (bản server giữ), `null` nếu chưa chốt.
  Map<String, Object?>? issuedInvoiceOf2(String studentId) =>
      _issued[_invoiceId2(studentId)];

  static String invoiceIdOf(String studentId) => _invoiceId(studentId);
  static String _invoiceId(String studentId) =>
      uid(int.parse(studentId.substring(studentId.length - 4)) + 200);

  /// Hóa đơn kỳ sau của học viên.
  static String invoice2IdOf(String studentId) => _invoiceId2(studentId);
  static String _invoiceId2(String studentId) =>
      uid(int.parse(studentId.substring(studentId.length - 4)) + 1200);

  /// Học viên và kỳ của một id hóa đơn (kỳ đầu hoặc kỳ sau), `null` nếu lạ.
  ({({String id, String name}) student, bool second})? _owner(String id) {
    for (final s in _students) {
      if (_invoiceId(s.id) == id) return (student: s, second: false);
      if (_invoiceId2(s.id) == id) return (student: s, second: true);
    }
    return null;
  }

  /// Tháng kế tiếp của [_month] (`YYYY-MM-01`).
  String get _month2 => _isoDate(DateTime(now.year, now.month + 1, 1));

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
        ..httpClientAdapter = this;

  // ---- dựng dữ liệu -------------------------------------------------------

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> _session() {
    final start = DateTime.parse('${sessionDate}T18:00:00+07:00').toUtc();
    return {
      'id': sessionId,
      'classId': classId,
      'className': className,
      'sessionDate': sessionDate,
      'startsAt': start.toIso8601String(),
      'endsAt': start
          .add(const Duration(hours: 1, minutes: 30))
          .toIso8601String(),
      'status': _attendance.isEmpty ? 'planned' : 'taught',
      'isMakeup': false,
      'cancelReason': null,
      'makeupOf': null,
    };
  }

  Map<String, Object?> _roster() => {
    'sessionId': sessionId,
    'classId': classId,
    'className': className,
    'sessionDate': sessionDate,
    'startsAt': _session()['startsAt'],
    'sessionStatus': _session()['status'],
    'canEdit': true,
    'editableUntil': now.add(const Duration(days: 7)).toUtc().toIso8601String(),
    'serverTime': now.toUtc().toIso8601String(),
    'items': [
      for (final s in _students)
        {
          'studentId': s.id,
          'fullName': s.name,
          'status': _attendance[s.id]?.status,
          'note': _attendance[s.id]?.note,
          'clientUpdatedAt': _attendance[s.id]?.at,
          'syncedAt': _attendance[s.id] == null
              ? null
              : now.toUtc().toIso8601String(),
        },
    ],
    'summary': _summary(),
  };

  Map<String, Object?> _summary() => {
    for (final k in ['present', 'late', 'excused', 'unexcused'])
      k: _attendance.values.where((a) => a.status == k).length,
  };

  Map<String, Object?> _invoice(({String id, String name}) s) {
    final id = _invoiceId(s.id);
    final frozen = _issued[id];
    if (frozen != null) return frozen;
    return _draft(
      s,
      id: id,
      periodId: periodId,
      month: _month,
      dueDate: _dueDate(),
      lines: _lines(s.id),
    );
  }

  Map<String, Object?> _draft(
    ({String id, String name}) s, {
    required String id,
    required String periodId,
    required String month,
    required String dueDate,
    required List<Map<String, Object?>> lines,
  }) {
    final sum = lines.fold<int>(0, (t, l) => t + (l['amount']! as int));
    return {
      'id': id,
      'periodId': periodId,
      'periodMonth': month,
      'code': null,
      'transferNote': null,
      'qrPayload': null,
      'status': 'draft',
      'studentId': s.id,
      'studentName': s.name,
      'totalAmount': sum < 0 ? 0 : sum,
      'paidAmount': 0,
      'carriedAmount': 0,
      'remainingAmount': 0,
      'dueDate': dueDate,
      'issuedAt': null,
      'payout': null,
      'voidedAt': null,
      'voidReason': null,
      'replacesInvoiceId': null,
      'replacementInvoiceId': null,
      'lines': lines,
      'installmentNo': null,
      'installmentCount': null,
      'clampedAmount': sum < 0 ? -sum : 0,
      'createdAt': now.toUtc().toIso8601String(),
    };
  }

  /// Còn nợ của các hóa đơn đã phát hành chưa hủy của học viên ở kỳ đầu: số
  /// "Nợ kỳ trước" (D6; sổ học viên không có số dư trong kịch bản).
  int _carryOf(String studentId) {
    final old = _issued[_invoiceId(studentId)];
    if (old == null || old['status'] == 'void') return 0;
    return old['remainingAmount']! as int;
  }

  /// Hóa đơn kỳ sau: bản nháp có dòng `carry_over` XEM TRƯỚC tính lại mỗi lần đọc
  /// (không ghi); sau khi phát hành thì đóng băng với số kết chuyển lúc chốt.
  Map<String, Object?> _invoice2(({String id, String name}) s) {
    final id = _invoiceId2(s.id);
    final frozen = _issued[id];
    if (frozen != null) return frozen;
    final n = int.parse(s.id.substring(s.id.length - 4));
    final lines = <Map<String, Object?>>[
      _line2(uid(1300 + n), 'monthly', 'Học phí tháng', _charges2[s.id]!),
      if (_carryOf(s.id) > 0)
        _line2(uid(1400 + n), 'carry_over', 'Nợ kỳ trước', _carryOf(s.id)),
    ];
    return _draft(
      s,
      id: id,
      periodId: periodId2,
      month: _month2,
      dueDate: _dueDate(second: true),
      lines: lines,
    );
  }

  Map<String, Object?> _line2(
    String id,
    String kind,
    String description,
    int amount,
  ) => {
    'id': id,
    'kind': kind,
    'description': description,
    'amount': amount,
    'charged': true,
    'notChargedReason': null,
    'sessionId': null,
    'sessionDate': null,
    'className': kind == 'monthly' ? className : null,
    'adjustmentReason': null,
  };

  /// Chỉ tính buổi đã điểm danh; vắng có phép không tính tiền.
  List<Map<String, Object?>> _lines(String studentId) {
    final a = _attendance[studentId];
    return [
      if (a != null)
        {
          'id': uid(300 + int.parse(studentId.substring(studentId.length - 4))),
          'kind': 'session',
          'description': 'Buổi $sessionDate',
          'amount': a.status == 'excused' ? 0 : feePerSession,
          'charged': a.status != 'excused',
          'notChargedReason': a.status == 'excused'
              ? 'excused_not_charged'
              : null,
          'sessionId': sessionId,
          'sessionDate': sessionDate,
          'className': className,
          'adjustmentReason': null,
        },
      ...?_adjustments[studentId],
    ];
  }

  String _dueDate({bool second = false}) => _isoDate(
    DateTime(
      now.year,
      now.month + (second ? 2 : 1),
      1,
    ).add(const Duration(days: 10)),
  );

  Map<String, Object?> _summaryOf(Map<String, Object?> inv) => {
    'id': inv['id'],
    'code': inv['code'],
    'status': inv['status'],
    'studentId': inv['studentId'],
    'studentName': inv['studentName'],
    'totalAmount': inv['totalAmount'],
    'hasOverride': false,
  };

  Map<String, Object?> _period({bool second = false}) {
    final all = second
        ? [
            for (final s in _students)
              if (_charges2.containsKey(s.id)) _invoice2(s),
          ]
        : [for (final s in _students) _invoice(s)];
    final drafts = all.where((i) => i['status'] == 'draft').toList();
    int sum(Iterable<Map<String, Object?>> l) =>
        l.fold(0, (t, i) => t + (i['totalAmount']! as int));
    // Đã phát hành = mọi trạng thái sau bản nháp (đã thu một phần/đủ vẫn tính).
    final issued = all
        .where((i) => i['status'] != 'draft' && i['status'] != 'void')
        .toList();
    final pending = drafts.where((i) => (i['totalAmount']! as int) > 0);
    return {
      'id': second ? periodId2 : periodId,
      'periodMonth': second ? _month2 : _month,
      'closeDate': _isoDate(
        DateTime(now.year, now.month + (second ? 2 : 1), 0),
      ),
      'dueDate': _dueDate(second: second),
      'status': pending.isEmpty && issued.isNotEmpty ? 'closed' : 'drafting',
      'draftCount': drafts.length,
      'issuedCount': issued.length,
      'voidCount': 0,
      'draftTotalAmount': sum(drafts),
      'issuedTotalAmount': sum(issued),
      'invoices': {
        'items': [for (final i in all) _summaryOf(i)],
        'total': all.length,
        'page': 1,
        'pageSize': 100,
      },
    };
  }

  Map<String, Object?> _issue(List<String>? ids, {bool second = false}) {
    final skipped = <Map<String, Object?>>[];
    final done = <Map<String, Object?>>[];
    for (final s in _students) {
      if (second && !_charges2.containsKey(s.id)) continue;
      final inv = second ? _invoice2(s) : _invoice(s);
      if (ids != null && !ids.contains(inv['id'])) continue;
      if (inv['status'] != 'draft') {
        skipped.add({
          'invoiceId': inv['id'],
          'studentName': s.name,
          'reason': 'NOT_DRAFT',
        });
        continue;
      }
      // Chỉ có số dư mà không có khoản phát sinh thì không phát hành (ZERO_AMOUNT).
      final total = inv['totalAmount']! as int;
      if (total == 0 || (second && _charges2[s.id] == 0)) {
        skipped.add({
          'invoiceId': inv['id'],
          'studentName': s.name,
          'reason': 'ZERO_AMOUNT',
        });
        continue;
      }
      final code = _codes.removeAt(0);
      final note = 'TH $code';
      final p = payout!;
      // Kết chuyển LÚC PHÁT HÀNH: nợ còn lại của hóa đơn cũ thành `carriedAmount`,
      // không còn tính vào `remainingAmount` của hóa đơn cũ (D6).
      if (second) _carryOldDebt(s.id);
      final frozen = {
        ...inv,
        'code': 'TH-$code',
        'transferNote': note,
        'qrPayload': 'VIETQR|${p['bankBin']}|${p['accountNo']}|$total|$note',
        'status': 'issued',
        'paidAmount': 0,
        'remainingAmount': total,
        'issuedAt': now.toUtc().toIso8601String(),
        'payout': p,
      };
      _issued[inv['id']! as String] = frozen;
      done.add(frozen);
    }
    return {
      'issuedCount': done.length,
      'skipped': skipped,
      'totalAmount': done.fold<int>(
        0,
        (t, i) => t + (i['totalAmount']! as int),
      ),
      'invoices': [
        for (final i in done)
          {
            for (final k in [
              'id',
              'code',
              'studentId',
              'studentName',
              'totalAmount',
              'dueDate',
              'transferNote',
              'qrPayload',
            ])
              k: i[k],
          },
      ],
    };
  }

  List<Map<String, Object?>> _newestFirst(List<Map<String, Object?>> l) {
    final order = {for (var i = 0; i < l.length; i++) l[i]['id']: i};
    return l..sort((a, b) {
      final byMonth = (b['periodMonth']! as String).compareTo(
        a['periodMonth']! as String,
      );
      return byMonth != 0
          ? byMonth
          : order[a['id']]!.compareTo(order[b['id']]!);
    });
  }

  void _carryOldDebt(String studentId) {
    final oldId = _invoiceId(studentId);
    final old = _issued[oldId];
    if (old == null || old['status'] == 'void') return;
    final left = old['remainingAmount']! as int;
    if (left == 0) return;
    _issued[oldId] = {
      ...old,
      'carriedAmount': (old['carriedAmount']! as int) + left,
      'remainingAmount': 0,
    };
  }

  Map<String, Object?> _familySummary(Map<String, Object?> i) => {
    'id': i['id'],
    'code': i['code'],
    'status': i['status'],
    'studentId': i['studentId'],
    'studentName': i['studentName'],
    'teacherName': teacherName,
    'periodMonth': i['periodMonth'],
    'totalAmount': i['totalAmount'],
    'paidAmount': i['paidAmount'],
    'carriedAmount': i['carriedAmount'],
    'remainingAmount': i['remainingAmount'],
    'dueDate': i['dueDate'],
    'issuedAt': i['issuedAt'],
  };

  Map<String, Object?> _familyDetail(Map<String, Object?> i) => {
    ..._familySummary(i),
    'lines': [
      for (final l in (i['lines']! as List).cast<Map<String, Object?>>())
        {
          'kind': l['kind'],
          'className': l['className'],
          'description': l['description'],
          'amount': l['amount'],
        },
    ],
    'payments': [
      // Biên nhận cho phụ huynh: không người ghi, ghi chú, lý do hủy.
      for (final p in (_payments[i['id']] ?? []).reversed)
        {
          for (final k in [
            'id',
            'amount',
            'method',
            'paidOn',
            'recordedAt',
            'voidedAt',
          ])
            k: p[k],
        },
    ],
    'transferNote': i['transferNote'],
    'qrPayload': i['qrPayload'],
    'payout': i['payout'],
    'voidedAt': i['voidedAt'],
  };

  /// Tính lại trạng thái và số liệu hóa đơn từ thanh toán còn hiệu lực.
  void _recalc(String invoiceId) {
    final inv = _issued[invoiceId]!;
    final total = inv['totalAmount']! as int;
    final carried = inv['carriedAmount']! as int;
    final paid = activePaymentsOf(
      invoiceId,
    ).fold<int>(0, (t, p) => t + (p['amount']! as int));
    _issued[invoiceId] = {
      ...inv,
      'status': paid == 0
          ? 'issued'
          : paid >= total
          ? 'paid'
          : 'partially_paid',
      'paidAmount': paid,
      // max(0, tổng − đã thu − đã chuyển sang kỳ sau).
      'remainingAmount': (total - paid - carried).clamp(0, total),
    };
  }

  Map<String, Object?> _paymentResult(Map<String, Object?> payment) {
    final inv = _issued[payment['invoiceId']]!;
    final paid = inv['paidAmount']! as int;
    final total = inv['totalAmount']! as int;
    return {
      'payment': payment,
      'status': inv['status'],
      'paidAmount': paid,
      'remainingAmount': inv['remainingAmount'],
      'overpaidAmount': paid > total ? paid - total : 0,
      'dunningCancelled': inv['status'] == 'paid',
    };
  }

  (int, Object) _recordPayment(String invoiceId, Map body, String key) {
    final replay = _payReplay[key];
    if (replay != null) return (replay.$1, replay.$2);
    final inv = _issued[invoiceId]!;
    // Đã thu đủ hoặc đã chuyển hết nợ sang kỳ sau: không ghi thêm.
    if (inv['status'] == 'paid' || inv['remainingAmount'] == 0) {
      return (409, _err('INVOICE_NOT_PAYABLE'));
    }
    if ((inv['carriedAmount']! as int) > 0 &&
        (body['amount'] as int) > (inv['remainingAmount']! as int)) {
      return (422, _err('VALIDATION_FAILED'));
    }
    // "Hôm nay" của app lấy từ đồng hồ máy (cubit hóa đơn không tiêm được giờ),
    // nên ngày thu hợp lệ so với ngày thật chứ không so với [now] cố định.
    final today = _isoDate(DateTime.now());
    final paidOn = body['paidOn'] as String? ?? today;
    if (paidOn.compareTo(today) > 0) return (422, _err('VALIDATION_FAILED'));
    payExecutions++;
    final actor = {'id': uid(900), 'name': teacherName};
    final payment = <String, Object?>{
      'id': uid(500 + ++_paymentSeq),
      'invoiceId': invoiceId,
      'amount': body['amount'],
      'method': body['method'],
      'paidOn': paidOn,
      'note': body['note'],
      'recordedAt': now.toUtc().toIso8601String(),
      'recordedBy': actor,
      'voidedAt': null,
      'voidedBy': null,
      'voidReason': null,
    };
    (_payments[invoiceId] ??= []).add(payment);
    _recalc(invoiceId);
    final out = (201, _paymentResult(payment));
    return _payReplay[key] = (out.$1, out.$2);
  }

  (int, Object) _voidPayment(String paymentId, Map body, String key) {
    final replay = _payReplay[key];
    if (replay != null) return (replay.$1, replay.$2);
    for (final MapEntry(key: invoiceId, value: list) in _payments.entries) {
      final i = list.indexWhere((p) => p['id'] == paymentId);
      if (i < 0) continue;
      // Hủy lại thanh toán đã hủy: 200 bản hiện tại, giữ lý do và người hủy đầu.
      if (list[i]['voidedAt'] == null) {
        list[i] = {
          ...list[i],
          'voidedAt': now.toUtc().toIso8601String(),
          'voidedBy': {'id': uid(900), 'name': teacherName},
          'voidReason': body['reason'],
        };
        _recalc(invoiceId);
      }
      final out = (200, _paymentResult(list[i]));
      return _payReplay[key] = (out.$1, out.$2);
    }
    return (404, _err('NOT_FOUND'));
  }

  // ---- HTTP ---------------------------------------------------------------

  static ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  static ResponseBody _error(int status, String code) =>
      _json(status, {'code': code, 'message': 'x', 'requestId': 'r'});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method;
    final m0 = method;
    final path = options.path;
    requests.add('$method $path');
    final op = _operation(method, path);
    if (op == null) return _error(404, 'NOT_FOUND');
    final body = options.data == null
        ? null
        : jsonDecode(jsonEncode(options.data));
    if (method == 'POST' && options.headers['Idempotency-Key'] is! String) {
      return _error(422, 'VALIDATION_FAILED');
    }
    final reqSchema = _requestSchema(op);
    if (reqSchema != null && !_valid(body, reqSchema)) {
      return _error(422, 'VALIDATION_FAILED');
    }
    if (m0 == 'GET' && path == '/sessions') {
      sessionDate = options.queryParameters['from'] as String? ?? sessionDate;
    }
    if (failPeriodGets > 0 &&
        m0 == 'GET' &&
        path == '/billing-periods/$periodId') {
      failPeriodGets--;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final (status, out) = _route(
      method,
      path,
      body,
      options.headers['Idempotency-Key'] as String?,
    );
    if (status < 300) {
      _conform(out, _responseSchema(op, status), '$method $path');
    }
    if (dropNextPayResponse &&
        method == 'POST' &&
        path.endsWith('/payments') &&
        status < 300) {
      dropNextPayResponse = false;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'response lost',
      );
    }
    if (dropNextIssueResponse && path.endsWith('/issue') && status < 300) {
      dropNextIssueResponse = false;
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'response lost',
      );
    }
    return _json(status, out);
  }

  (int, Object) _route(String method, String path, Object? body, String? key) {
    final m = '$method $path';
    if (m == 'GET /sessions') {
      return (
        200,
        {
          'items': [_session()],
        },
      );
    }
    if (m == 'GET /sessions/$sessionId/attendance') return (200, _roster());
    if (m == 'POST /attendance/sync') return _sync(body! as Map, key!);
    if (m == 'GET /payout-accounts') {
      final p = payout;
      return (
        200,
        {
          'items': [
            if (p != null)
              {
                'id': uid(50),
                'bankBin': p['bankBin'],
                'accountNoMasked':
                    '******${(p['accountNo']! as String).substring(6)}',
                'accountName': p['accountName'],
                'isPrimary': true,
                'createdAt': now.toUtc().toIso8601String(),
              },
          ],
        },
      );
    }
    if (m == 'GET /family/students') {
      final seen = <Object?>{};
      return (
        200,
        {
          'items': [
            for (final i in _issued.values)
              if (seen.add(i['studentId']))
                {
                  'id': i['studentId'],
                  'fullName': i['studentName'],
                  'classes': [],
                },
          ],
        },
      );
    }
    if (m == 'GET /billing-periods') {
      return (
        200,
        {
          'items': [
            // Kỳ mới nhất trước.
            if (_charges2.isNotEmpty)
              {
                for (final e in _period(second: true).entries)
                  if (e.key != 'invoices') e.key: e.value,
              },
            if (_attendance.isNotEmpty)
              {
                for (final e in _period().entries)
                  if (e.key != 'invoices') e.key: e.value,
              },
          ],
          'total': (_attendance.isEmpty ? 0 : 1) + (_charges2.isEmpty ? 0 : 1),
          'page': 1,
          'pageSize': 100,
        },
      );
    }
    if (m == 'GET /billing-periods/$periodId') return (200, _period());
    if (m == 'GET /billing-periods/$periodId2') {
      return (200, _period(second: true));
    }
    if (m == 'POST /billing-periods/$periodId2/issue') {
      issueKeys.add(key!);
      final replay = _issueReplay[key];
      if (replay != null) return (200, replay);
      if (payout == null) return (422, _err('PAYOUT_ACCOUNT_MISSING'));
      final ids = (body! as Map)['invoiceIds'] as List?;
      issueExecutions++;
      return (
        200,
        _issueReplay[key] = _issue(ids?.cast<String>(), second: true),
      );
    }
    if (m == 'POST /billing-periods/$periodId/issue') {
      issueKeys.add(key!);
      if (staleIssues > 0) {
        staleIssues--;
        return (409, _err('CONFLICT_STALE'));
      }
      final replay = _issueReplay[key];
      if (replay != null) return (200, replay);
      if (payout == null) return (422, _err('PAYOUT_ACCOUNT_MISSING'));
      final ids = (body! as Map)['invoiceIds'] as List?;
      issueExecutions++;
      return (200, _issueReplay[key] = _issue(ids?.cast<String>()));
    }
    final pay = RegExp(
      r'^(GET|POST) /invoices/([^/]+)/payments$',
    ).firstMatch(m);
    if (pay != null) {
      final id = pay.group(2)!;
      if (_owner(id) == null) return (404, _err('NOT_FOUND'));
      final issued = _issued.containsKey(id);
      if (pay.group(1) == 'GET') {
        return issued
            ? (200, {'items': (_payments[id] ?? []).reversed.toList()})
            : (404, _err('NOT_FOUND'));
      }
      payKeys.add(key!);
      // Bản nháp chưa phát hành không ghi thanh toán được.
      if (!issued) return (409, _err('INVOICE_NOT_PAYABLE'));
      return _recordPayment(id, body! as Map, key);
    }
    final voidPay = RegExp(r'^POST /payments/([^/]+)/void$').firstMatch(m);
    if (voidPay != null) {
      return _voidPayment(voidPay.group(1)!, body! as Map, key!);
    }
    final inv = RegExp(
      r'^(GET|POST) /invoices/([^/]+)(/adjustments)?$',
    ).firstMatch(m);
    if (inv != null) {
      final owner = _owner(inv.group(2)!);
      if (owner == null) return (404, _err('NOT_FOUND'));
      final student = owner.student;
      if (inv.group(3) == null) {
        return (200, owner.second ? _invoice2(student) : _invoice(student));
      }
      // Kịch bản chưa điều chỉnh bản nháp của kỳ sau.
      if (owner.second) return (409, _err('INVOICE_IMMUTABLE'));
      if (_issued.containsKey(inv.group(2))) {
        return (409, _err('INVOICE_IMMUTABLE'));
      }
      final b = body! as Map;
      (_adjustments[student.id] ??= []).add({
        'id': uid(
          400 +
              (_adjustments[student.id]?.length ?? 0) +
              int.parse(student.id.substring(student.id.length - 4)) * 10,
        ),
        'kind': 'manual_adjustment',
        'description': b['description'],
        'amount': b['amount'],
        'charged': true,
        'notChargedReason': null,
        'sessionId': null,
        'sessionDate': null,
        'className': null,
        'adjustmentReason': b['adjustmentReason'],
      });
      return (201, _invoice(student));
    }
    // Phụ huynh chỉ thấy hóa đơn đã phát hành.
    if (m == 'GET /family/invoices') {
      return (
        200,
        {
          // Mới nhất trước (cùng kỳ giữ thứ tự phát hành).
          'items': [
            for (final i in _newestFirst(_issued.values.toList()))
              _familySummary(i),
          ],
          'nextCursor': null,
        },
      );
    }
    final fam = RegExp(r'^GET /family/invoices/([^/]+)$').firstMatch(m);
    if (fam != null) {
      final i = _issued[fam.group(1)];
      return i == null ? (404, _err('NOT_FOUND')) : (200, _familyDetail(i));
    }
    return (404, _err('NOT_FOUND'));
  }

  Map<String, Object?> _err(String code) => {
    'code': code,
    'message': 'x',
    'requestId': 'r',
  };

  (int, Object) _sync(Map body, String key) {
    final replay = _syncReplay[key];
    if (replay != null) return (200, replay);
    final results = <Map<String, Object?>>[];
    for (final m in (body['mutations'] as List).cast<Map>()) {
      _attendance[m['studentId'] as String] = (
        status: m['status'] as String,
        note: m['note'] as String?,
        at: m['clientUpdatedAt'] as String,
      );
      results.add({
        'clientMutationId': m['clientMutationId'],
        'studentId': m['studentId'],
        'result': 'applied',
      });
    }
    return (
      200,
      _syncReplay[key] = {
        'sessionId': sessionId,
        'sessionStatus': 'taught',
        'serverTime': now.toUtc().toIso8601String(),
        'results': results,
        'summary': _summary(),
        'parentsToNotify': 0,
      },
    );
  }

  // ---- đối chiếu hợp đồng -------------------------------------------------

  /// Tìm thao tác của hợp đồng theo method và đường dẫn thật (`/x/{id}`).
  Map<String, dynamic>? _operation(String method, String path) {
    final spec = _openapi;
    if (spec == null) return const {};
    for (final MapEntry(:key, :value) in (spec['paths'] as Map).entries) {
      final template = (key as String).replaceFirst('/v1', '');
      final re = RegExp(
        '^${template.replaceAll(RegExp(r'\{[^}]+\}'), '[^/]+')}\$',
      );
      if (re.hasMatch(path)) {
        final op = (value as Map)[method.toLowerCase()];
        if (op != null) return op as Map<String, dynamic>;
      }
    }
    return null;
  }

  Map<String, dynamic>? _requestSchema(Map<String, dynamic> op) {
    final c = (op['requestBody'] as Map?)?['content'] as Map?;
    return (c?['application/json'] as Map?)?['schema'] as Map<String, dynamic>?;
  }

  Map<String, dynamic> _responseSchema(Map<String, dynamic> op, int status) {
    final r = (op['responses'] as Map)['$status'] as Map;
    return ((r['content'] as Map)['application/json'] as Map)['schema']
        as Map<String, dynamic>;
  }

  bool _valid(Object? v, Map<String, dynamic> schema) {
    try {
      _conform(v, schema, 'request');
      return true;
    } on StateError {
      return false;
    }
  }

  /// Kiểm giá trị theo schema: kiểu, enum, mẫu chuỗi, trường bắt buộc và không
  /// có trường lạ khi `additionalProperties: false`.
  void _conform(Object? v, Map<String, dynamic> s, String at) {
    final spec = _openapi;
    if (spec == null) return;
    final ref = s[r'$ref'] as String?;
    if (ref != null) {
      final schemas =
          (spec['components'] as Map)['schemas'] as Map<String, dynamic>;
      return _conform(
        v,
        schemas[ref.split('/').last] as Map<String, dynamic>,
        at,
      );
    }
    for (final k in ['oneOf', 'anyOf', 'allOf']) {
      final options = s[k] as List?;
      if (options == null) continue;
      if (k == 'allOf') {
        for (final o in options) {
          _conform(v, o as Map<String, dynamic>, at);
        }
        return;
      }
      if (v == null && options.any((o) => (o as Map)['type'] == 'null')) return;
      for (final o in options) {
        try {
          return _conform(v, o as Map<String, dynamic>, at);
        } on StateError {
          continue;
        }
      }
      throw StateError('$at: không khớp $k');
    }
    final type = s['type'];
    final types = type is List ? type : [type];
    if (v == null) {
      if (!types.contains('null')) throw StateError('$at: null không hợp lệ');
      return;
    }
    bool ok(Object? t) => switch (t) {
      'string' => v is String,
      'integer' => v is int,
      'number' => v is num,
      'boolean' => v is bool,
      'array' => v is List,
      'object' => v is Map,
      _ => true,
    };
    if (!types.any(ok)) throw StateError('$at: sai kiểu ($v, cần $type)');
    if (s['enum'] case final List e when !e.contains(v)) {
      throw StateError('$at: $v ngoài enum $e');
    }
    if (v is String && s['pattern'] is String) {
      if (!RegExp(s['pattern'] as String).hasMatch(v)) {
        throw StateError('$at: "$v" sai mẫu ${s['pattern']}');
      }
    }
    if (v is int && s['minimum'] is num && v < (s['minimum'] as num)) {
      throw StateError('$at: $v < ${s['minimum']}');
    }
    if (v is List) {
      final item = s['items'];
      if (item is Map<String, dynamic>) {
        for (var i = 0; i < v.length; i++) {
          _conform(v[i], item, '$at[$i]');
        }
      }
    }
    if (v is Map) {
      final props = (s['properties'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final r in (s['required'] as List? ?? const [])) {
        if (!v.containsKey(r)) throw StateError('$at: thiếu "$r"');
      }
      for (final MapEntry(:key, :value) in v.entries) {
        final sub = props[key];
        if (sub == null) {
          if (s['additionalProperties'] == false) {
            throw StateError('$at: trường lạ "$key"');
          }
          continue;
        }
        _conform(value, sub as Map<String, dynamic>, '$at.$key');
      }
    }
  }

  @override
  void close({bool force = false}) {}
}
