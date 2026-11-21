import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/billing/cubit/billing_periods_cubit.dart'
    show BillingLoad;
import 'package:teacher/features/receivables/cubit/dunning_settings_cubit.dart';
import 'package:teacher/features/receivables/cubit/invoice_dunning_cubit.dart';
import 'package:teacher/features/receivables/cubit/receivables_cubit.dart';
import 'package:teacher/features/receivables/cubit/student_receivable_cubit.dart';
import 'package:teacher/features/receivables/data/receivable_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_receivables_repository.dart';

ApiException fieldErr(Map<String, List<String>> errors) => ApiException(
  code: ApiErrorCode.validationFailed,
  wireCode: 'VALIDATION_FAILED',
  status: 422,
  fieldErrors: errors,
);

void main() {
  late FakeReceivablesRepository repo;
  setUp(() => repo = FakeReceivablesRepository());

  group('ReceivablesCubit (AC-1)', () {
    List<ReceivableRow> many(int n) => [
      for (var i = 0; i < n; i++)
        sampleRow(id: 's$i', name: 'Học viên $i', amount: 1000000 + i * 1000),
    ];

    test(
      'tải trang đầu: sắp theo số nợ giảm dần, kèm tổng theo nhóm',
      () async {
        repo.rows = [
          sampleRow(id: 'a', name: 'An', amount: 300000),
          sampleRow(
            id: 'b',
            name: 'Bình',
            amount: 900000,
            bucket: AgingBucket.over60,
            overdue: 75,
          ),
        ];
        final c = ReceivablesCubit(repo);
        await c.load();
        expect(c.state.load, BillingLoad.ready);
        expect(c.state.items.map((r) => r.studentName), ['Bình', 'An']);
        expect(c.state.totalAmount, 1200000);
        expect(c.state.buckets.map((b) => (b.bucket, b.totalAmount)), [
          (AgingBucket.upTo30, 300000),
          (AgingBucket.from31To60, 0),
          (AgingBucket.over60, 900000),
        ]);
        expect(c.state.unfiltered, isTrue);
      },
    );

    test('không ai nợ: rỗng, không lọc', () async {
      final c = ReceivablesCubit(repo);
      await c.load();
      expect(c.state.items, isEmpty);
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.unfiltered, isTrue);
    });

    test('lọc nhóm: danh sách theo nhóm, tổng theo nhóm không đổi', () async {
      repo.rows = [
        sampleRow(id: 'a', amount: 300000),
        sampleRow(id: 'b', amount: 900000, bucket: AgingBucket.over60),
      ];
      final c = ReceivablesCubit(repo);
      await c.load();
      await c.setBucket(AgingBucket.over60);
      expect(c.state.items.map((r) => r.studentId), ['b']);
      expect(c.state.totalAmount, 1200000);
      expect(repo.listArgs.last.bucket, AgingBucket.over60);
      expect(c.state.unfiltered, isFalse);
      await c.setBucket(null);
      expect(c.state.items, hasLength(2));
    });

    test('tìm theo tên: dưới 2 ký tự bỏ qua, từ 2 ký tự gửi lên', () async {
      repo.rows = [
        sampleRow(id: 'a', name: 'An'),
        sampleRow(id: 'b', name: 'Bình'),
      ];
      final c = ReceivablesCubit(repo);
      await c.load();
      await c.setQuery(' B ');
      expect(repo.listArgs.last.q, isNull);
      expect(c.state.items, hasLength(2));
      await c.setQuery('Bì');
      expect(repo.listArgs.last.q, 'Bì');
      expect(c.state.items.map((r) => r.studentId), ['b']);
    });

    test('đổi chiều sắp xếp', () async {
      repo.rows = [
        sampleRow(id: 'a', amount: 300000),
        sampleRow(id: 'b', amount: 900000),
      ];
      final c = ReceivablesCubit(repo);
      await c.load();
      await c.toggleSort();
      expect(c.state.ascending, isTrue);
      expect(c.state.items.map((r) => r.studentId), ['a', 'b']);
    });

    test('tải thêm: nối trang kế, hết thì dừng', () async {
      repo.rows = many(25);
      final c = ReceivablesCubit(repo);
      await c.load();
      expect(c.state.items, hasLength(20));
      expect(c.state.hasMore, isTrue);
      await c.loadMore();
      expect(c.state.items, hasLength(25));
      expect(c.state.hasMore, isFalse);
      await c.loadMore();
      expect(repo.calls.where((x) => x.startsWith('list')), [
        'list:1',
        'list:2',
      ]);
    });

    test('tải thêm lỗi: giữ danh sách, báo thử lại được', () async {
      repo.rows = many(25);
      final c = ReceivablesCubit(repo);
      await c.load();
      repo.listError = const ApiException.network();
      await c.loadMore();
      expect(c.state.items, hasLength(20));
      expect(c.state.moreFailed, isTrue);
      await c.loadMore();
      expect(c.state.items, hasLength(25));
      expect(c.state.moreFailed, isFalse);
    });

    test('lỗi tải đầu: failure; thử lại tải được', () async {
      repo
        ..listError = const ApiException.network()
        ..rows = [sampleRow()];
      final c = ReceivablesCubit(repo);
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      expect(c.state.error, isNotNull);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.items, hasLength(1));
    });

    test('làm mới lỗi: giữ danh sách đang có', () async {
      repo.rows = [sampleRow()];
      final c = ReceivablesCubit(repo);
      await c.load();
      repo.listError = const ApiException.network();
      await c.refresh();
      expect(c.state.load, BillingLoad.ready);
      expect(c.state.items, hasLength(1));
    });

    test('phản hồi của bộ lọc cũ bị bỏ qua', () async {
      repo.rows = [
        sampleRow(id: 'a'),
        sampleRow(id: 'b', bucket: AgingBucket.over60),
      ];
      final c = ReceivablesCubit(repo);
      await c.load();
      repo.listGate = Completer<void>();
      final slow = c.setBucket(AgingBucket.upTo30);
      final gate = repo.listGate!;
      repo.listGate = null;
      await c.setBucket(AgingBucket.over60);
      gate.complete();
      await slow;
      expect(c.state.bucket, AgingBucket.over60);
      expect(c.state.items.map((r) => r.studentId), ['b']);
    });
  });

  group('StudentReceivableCubit (AC-2, AC-4)', () {
    const twoClasses = [
      ReceivableEnrollment(
        enrollmentId: 'e1',
        classId: 'c1',
        className: 'Toán 9A',
        dunningEnabled: true,
      ),
      ReceivableEnrollment(
        enrollmentId: 'e2',
        classId: 'c2',
        className: 'Lý 9A',
        dunningEnabled: true,
      ),
    ];

    test('tải lịch sử hóa đơn, thanh toán, nhắc nợ', () async {
      final c = StudentReceivableCubit(repo, 's1');
      await c.load();
      final h = c.state.history!;
      expect(h.invoices.single.remainingAmount, 700000);
      expect(h.payments.single.amount, 500000);
      expect(h.reminders.single.step.status, DunningStepStatus.sent);
    });

    test('lỗi tải: failure kèm lỗi; thử lại tải được', () async {
      repo.historyError = const ApiException.network();
      final c = StudentReceivableCubit(repo, 's1');
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      expect(c.state.error, isNotNull);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
    });

    test(
      'tắt rồi bật nhắc nợ một ghi danh: lấy cờ học viên từ server',
      () async {
        repo.histories['s1'] = sampleHistory(enrollments: twoClasses);
        final c = StudentReceivableCubit(repo, 's1');
        await c.load();
        await c.setDunning('e1', false);
        expect(repo.calls, contains('toggle:e1:false'));
        expect(c.state.history!.enrollments.map((e) => e.dunningEnabled), [
          false,
          true,
        ]);
        // Còn một lớp bật nên học viên vẫn được nhắc.
        expect(c.state.history!.dunningEnabled, isTrue);
        await c.setDunning('e2', false);
        expect(c.state.history!.dunningEnabled, isFalse);
        await c.setDunning('e2', true);
        expect(c.state.history!.dunningEnabled, isTrue);
        expect(c.state.toggling, isEmpty);
      },
    );

    test('bật/tắt lỗi: giữ trạng thái cũ và báo lỗi', () async {
      final c = StudentReceivableCubit(repo, 's1');
      await c.load();
      repo.toggleError = const ApiException.network();
      await c.setDunning('e1', false);
      expect(c.state.history!.enrollments.single.dunningEnabled, isTrue);
      expect(c.state.error, isNotNull);
      expect(c.state.toggling, isEmpty);
    });

    test('đang gọi thì bỏ qua lần bấm thứ hai', () async {
      final c = StudentReceivableCubit(repo, 's1');
      await c.load();
      final a = c.setDunning('e1', false);
      final b = c.setDunning('e1', false);
      await Future.wait([a, b]);
      expect(repo.calls.where((x) => x.startsWith('toggle')), hasLength(1));
    });
  });

  group('DunningSettingsCubit (AC-3)', () {
    test('tải mặc định -1, 0, 3, 7; chưa sửa thì chưa có gì để lưu', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      expect(c.state.enabled, isTrue);
      expect(c.state.offsets, [-1, 0, 3, 7]);
      expect(c.state.dirty, isFalse);
    });

    test(
      'thêm mốc giữ thứ tự tăng dần; trùng, ngoài khoảng, quá 6 bị chặn',
      () async {
        final c = DunningSettingsCubit(repo);
        await c.load();
        c.addOffset(5);
        expect(c.state.offsets, [-1, 0, 3, 5, 7]);
        c.addOffset(3);
        expect(c.state.offsetError, OffsetError.duplicate);
        c.addOffset(31);
        expect(c.state.offsetError, OffsetError.range);
        c.addOffset(-8);
        expect(c.state.offsetError, OffsetError.range);
        c.addOffset(10);
        expect(c.state.offsets, hasLength(6));
        c.addOffset(14);
        expect(c.state.offsetError, OffsetError.tooMany);
        expect(c.state.offsets, hasLength(6));
      },
    );

    test('xóa mốc; mốc cuối không xóa được', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      c.removeOffset(-1);
      c.removeOffset(0);
      c.removeOffset(3);
      expect(c.state.offsets, [7]);
      c.removeOffset(7);
      expect(c.state.offsets, [7]);
      expect(c.state.offsetError, OffsetError.tooFew);
    });

    test('lưu: PUT toàn bộ cài đặt, lấy lại bản server', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      c
        ..setEnabled(false)
        ..addOffset(14);
      expect(c.state.dirty, isTrue);
      await c.save();
      expect(repo.putBodies.single.enabled, isFalse);
      expect(repo.putBodies.single.offsetsDays, [-1, 0, 3, 7, 14]);
      expect(c.state.justSaved, isTrue);
      expect(c.state.dirty, isFalse);
    });

    test(
      'lưu gặp 422 tại offsetsDays: lỗi gắn ở trường, giữ bản đang sửa',
      () async {
        final c = DunningSettingsCubit(repo);
        await c.load();
        c.addOffset(14);
        repo.putError = fieldErr({
          'offsetsDays': ['Mốc phải tăng dần'],
        });
        await c.save();
        expect(c.state.serverErrors, ['Mốc phải tăng dần']);
        expect(c.state.error, isNull);
        expect(c.state.offsets, [-1, 0, 3, 7, 14]);
        expect(c.state.dirty, isTrue);
        expect(c.state.justSaved, isFalse);
      },
    );

    test('lưu lỗi mạng: báo chung, giữ bản đang sửa', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      c.setEnabled(false);
      repo.putError = const ApiException.network();
      await c.save();
      expect(c.state.error, isNotNull);
      expect(c.state.enabled, isFalse);
    });

    test('xem trước mẫu tin của một mốc; lỗi thì báo thử lại', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      await c.showPreview(3);
      expect(repo.calls, contains('preview:3'));
      expect(c.state.preview!.preview!.body, contains('mốc 3'));
      repo.previewError = const ApiException.network();
      await c.showPreview(7);
      expect(c.state.preview!.failed, isTrue);
    });

    test('lỗi tải: failure', () async {
      repo.settingsError = const ApiException.network();
      final c = DunningSettingsCubit(repo);
      await c.load();
      expect(c.state.load, BillingLoad.failure);
    });
  });

  group('InvoiceDunningCubit (AC-5)', () {
    test('tải trạng thái nhắc: lần đã gửi và lần tới', () async {
      final c = InvoiceDunningCubit(repo, 'i1');
      await c.load();
      final d = c.state.dunning!;
      expect(d.lastSent!.offsetDays, -1);
      expect(d.next!.offsetDays, 0);
    });

    test('đã tắt: không có lần nhắc tới dù còn mốc chờ', () async {
      repo.invoiceDunnings['i1'] = InvoiceDunning(
        enabled: false,
        disabledReason: DunningDisabledReason.studentDisabled,
        steps: [sampleStep(offset: 0, status: DunningStepStatus.pending)],
      );
      final c = InvoiceDunningCubit(repo, 'i1');
      await c.load();
      expect(c.state.dunning!.next, isNull);
    });

    test('lỗi: failure riêng; thử lại tải được', () async {
      repo.invoiceDunningError = const ApiException.network();
      final c = InvoiceDunningCubit(repo, 'i1');
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
    });
  });

  group('ReceivablesCubit: chạy chồng nhau', () {
    List<ReceivableRow> many(int n) => [
      for (var i = 0; i < n; i++)
        sampleRow(id: 's$i', name: 'Học viên $i', amount: 1000000 + i * 1000),
    ];

    test('loadMore đang bay rồi refresh: trang 2 cũ không nối vào', () async {
      repo.rows = many(25);
      final c = ReceivablesCubit(repo);
      await c.load();
      final gate = repo.pageGates[2] = Completer<void>();
      final more = c.loadMore();
      expect(c.state.loadingMore, isTrue);
      await c.refresh();
      // Làm mới đã bỏ lần tải thêm: cờ không kẹt.
      expect(c.state.loadingMore, isFalse);
      repo.pageGates.remove(2);
      gate.complete();
      await more;
      expect(c.state.items, hasLength(20));
      expect(c.state.page, 1);
      expect(c.state.loadingMore, isFalse);
    });

    test(
      'refresh lỗi lúc loadMore đang bay: không kẹt loadingMore, báo nhẹ',
      () async {
        repo.rows = many(25);
        final c = ReceivablesCubit(repo);
        await c.load();
        final gate = repo.pageGates[2] = Completer<void>();
        final more = c.loadMore();
        repo.listError = const ApiException.network();
        await c.refresh();
        expect(c.state.loadingMore, isFalse);
        expect(c.state.moreFailed, isFalse);
        expect(c.state.refreshError, isNotNull);
        expect(c.state.items, hasLength(20));
        repo.pageGates.remove(2);
        gate.complete();
        await more;
        expect(c.state.loadingMore, isFalse);
        expect(c.state.items, hasLength(20));
      },
    );

    test('đang refresh thì loadMore không chạy', () async {
      repo.rows = many(25);
      final c = ReceivablesCubit(repo);
      await c.load();
      final gate = repo.pageGates[1] = Completer<void>();
      final refresh = c.refresh();
      await c.loadMore();
      expect(repo.calls.where((x) => x == 'list:2'), isEmpty);
      repo.pageGates.remove(1);
      gate.complete();
      await refresh;
      expect(c.state.items, hasLength(20));
    });

    test(
      'đổi lọc lúc loadMore đang bay: kết quả lọc mới, không lẫn trang cũ',
      () async {
        repo.rows = [
          ...many(25),
          sampleRow(id: 'z', amount: 5, bucket: AgingBucket.over60),
        ];
        final c = ReceivablesCubit(repo);
        await c.load();
        final gate = repo.pageGates[2] = Completer<void>();
        final more = c.loadMore();
        await c.setBucket(AgingBucket.over60);
        repo.pageGates.remove(2);
        gate.complete();
        await more;
        expect(c.state.items.map((r) => r.studentId), ['z']);
        expect(c.state.loadingMore, isFalse);
        expect(c.state.bucket, AgingBucket.over60);
      },
    );

    test('lọc theo lớp: gửi classId, tổng theo đúng lớp', () async {
      repo.rows = [
        sampleRow(id: 'a', amount: 100),
        sampleRow(id: 'b', amount: 200),
      ];
      repo.studentClass.addAll({'a': 'c1', 'b': 'c2'});
      final c = ReceivablesCubit(repo);
      await c.load();
      await c.setClass('c2');
      expect(repo.listArgs.last.classId, 'c2');
      expect(c.state.items.map((r) => r.studentId), ['b']);
      expect(c.state.totalAmount, 200);
      expect(c.state.unfiltered, isFalse);
      await c.setClass(null);
      expect(c.state.items, hasLength(2));
    });

    test(
      'gõ 1 ký tự không gọi lại API; chỉ khi từ khóa hiệu lực đổi',
      () async {
        repo.rows = [
          sampleRow(id: 'a', name: 'An'),
          sampleRow(id: 'b', name: 'Bình'),
        ];
        final c = ReceivablesCubit(repo);
        await c.load();
        await c.setQuery('b');
        expect(repo.calls, ['list:1']);
        await c.setQuery('bì');
        expect(repo.calls, ['list:1', 'list:1']);
        await c.setQuery('bìn');
        await c.setQuery('b');
        expect(repo.listArgs.last.q, isNull);
        expect(c.state.items, hasLength(2));
      },
    );
  });

  group('cubit: các nit an toàn', () {
    test('StudentReceivableCubit: phản hồi refresh cũ bị bỏ', () async {
      repo.histories['s1'] = sampleHistory(name: 'Cũ');
      final c = StudentReceivableCubit(repo, 's1');
      await c.load();
      final gate = repo.historyGate = Completer<void>();
      final stale = c.refresh();
      repo.historyGate = null;
      repo.histories['s1'] = sampleHistory(name: 'Mới');
      await c.refresh();
      gate.complete();
      await stale;
      expect(c.state.history!.studentName, 'Mới');
    });

    test('xóa mốc đang xem trước: preview đến muộn không hiện lại', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      final gate = repo.previewGate = Completer<void>();
      final shown = c.showPreview(3);
      c.removeOffset(3);
      expect(c.state.preview, isNull);
      repo.previewGate = null;
      gate.complete();
      await shown;
      expect(c.state.preview, isNull);
    });

    test('đặt lại mặc định hủy preview đang chờ', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      final gate = repo.previewGate = Completer<void>();
      final shown = c.showPreview(7);
      c.resetOffsets();
      repo.previewGate = null;
      gate.complete();
      await shown;
      expect(c.state.preview, isNull);
    });

    test('đang lưu thì khóa thêm, xóa, đặt lại mốc và công tắc', () async {
      final c = DunningSettingsCubit(repo);
      await c.load();
      c.addOffset(14);
      final gate = repo.putGate = Completer<void>();
      final saving = c.save();
      expect(c.state.saving, isTrue);
      c
        ..addOffset(20)
        ..removeOffset(0)
        ..resetOffsets()
        ..setEnabled(false);
      expect(c.state.offsets, [-1, 0, 3, 7, 14]);
      expect(c.state.enabled, isTrue);
      repo.putGate = null;
      gate.complete();
      await saving;
      expect(repo.putBodies.single.offsetsDays, [-1, 0, 3, 7, 14]);
    });

    test('mốc nhắc lạ không tính là lần nhắc tới', () {
      final d = InvoiceDunning.fromJson({
        'enabled': true,
        'disabledReason': null,
        'steps': [
          {
            'offsetDays': 0,
            'scheduledFor': '2027-01-10T09:00:00+07:00',
            'status': 'snoozed',
            'sentAt': null,
          },
        ],
      });
      expect(d.steps.single.status, DunningStepStatus.unknown);
      expect(d.next, isNull);
      expect(d.lastSent, isNull);
    });
  });

  group('lỗi lạ (FormatException) không làm kẹt cờ', () {
    const bad = FormatException('hỏng');

    test('ReceivablesCubit: tải đầu, thử lại chạy được', () async {
      repo
        ..listError = bad
        ..rows = [sampleRow()];
      final c = ReceivablesCubit(repo);
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      expect(c.state.error, isNotNull);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
    });

    test(
      'ReceivablesCubit: loadMore lỗi lạ báo thử lại; refresh lỗi lạ báo nhẹ',
      () async {
        repo.rows = [
          for (var i = 0; i < 25; i++) sampleRow(id: 's$i', amount: 1000 + i),
        ];
        final c = ReceivablesCubit(repo);
        await c.load();
        repo.listError = bad;
        await c.loadMore();
        expect(c.state.loadingMore, isFalse);
        expect(c.state.moreFailed, isTrue);
        await c.loadMore();
        expect(c.state.items, hasLength(25));
        repo.listError = bad;
        await c.refresh();
        expect(c.state.refreshError, isNotNull);
        // Cờ đang tải trang 1 đã tắt: loadMore/refresh sau đó vẫn chạy.
        await c.refresh();
        expect(c.state.refreshError, isNull);
      },
    );

    test('StudentReceivableCubit: tải và bật/tắt', () async {
      repo.historyError = bad;
      final c = StudentReceivableCubit(repo, 's1');
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.load();
      repo.toggleError = bad;
      await c.setDunning('e1', false);
      expect(c.state.toggling, isEmpty);
      expect(c.state.error, isNotNull);
    });

    test('DunningSettingsCubit: tải, lưu, xem trước', () async {
      repo.settingsError = bad;
      final c = DunningSettingsCubit(repo);
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.load();
      c.addOffset(14);
      repo.putError = bad;
      await c.save();
      expect(c.state.saving, isFalse);
      expect(c.state.error, isNotNull);
      repo.previewError = bad;
      await c.showPreview(3);
      expect(c.state.preview!.failed, isTrue);
    });

    test('InvoiceDunningCubit', () async {
      repo.invoiceDunningError = bad;
      final c = InvoiceDunningCubit(repo, 'i1');
      await c.load();
      expect(c.state.load, BillingLoad.failure);
      await c.load();
      expect(c.state.load, BillingLoad.ready);
    });
  });
}
