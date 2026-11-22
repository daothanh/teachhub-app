import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:parent/features/family/data/family_models.dart';
import 'package:parent/features/family/data/family_repository.dart';
import 'package:parent/features/invoice/cubit/receipt_claim_cubit.dart';
import 'package:parent/features/invoice/data/invoice_models.dart';
import 'package:parent/features/invoice/data/invoice_repository.dart';
import 'package:parent/features/invoice/data/qr_image_saver.dart';
import 'package:parent/features/invoice/data/receipt_models.dart';
import 'package:parent/features/invoice/data/receipt_picker.dart';
import 'package:parent/features/invoice/data/receipt_repository.dart';
import 'package:parent/l10n/l10n.dart';
import 'package:parent/parent.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

const _invoiceId = '019c0a10-0001-7b30-8c01-000000000001';
final _openapi =
    jsonDecode(
          File(
            '../../packages/teachhub_shared/contracts/openapi.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final _schemas =
    (_openapi['components'] as Map)['schemas'] as Map<String, dynamic>;

Map<String, dynamic> _example(String name) =>
    (_schemas[name] as Map)['example'] as Map<String, dynamic>;

ReceiptImage _img({int size = 1000, String mime = 'image/jpeg'}) =>
    ReceiptImage(
      fileName: 'bien-lai.jpg',
      mimeType: mime,
      bytes: Uint8List(size),
    );

ApiException _http(int status, [String? code]) =>
    ApiException.fromResponse(status, {'code': code});

final _now = DateTime.utc(2027, 1, 5, 2);

UploadTicket _ticket({String id = 'f1', int validSeconds = 120}) =>
    UploadTicket(
      fileId: id,
      uploadUrl: 'https://files.example.invalid/$id',
      headers: const {'Content-Type': 'image/jpeg'},
      expiresAt: _now.add(Duration(seconds: validSeconds)),
    );

/// Mỗi lệnh có thể xếp hàng lỗi để phát ở lần gọi kế tiếp.
class _FakeReceipts implements ReceiptRepository {
  final calls = <String>[];
  final claimKeys = <String>[];
  final uploadKeys = <String>[];
  final errors = <String, List<Object>>{};
  var tickets = 0;
  int validSeconds = 120;
  void Function()? onClaim;

  void _maybeFail(String op) {
    final q = errors[op];
    if (q != null && q.isNotEmpty) throw q.removeAt(0);
  }

  @override
  Future<UploadTicket> requestUpload(
    String invoiceId,
    ReceiptImage image, {
    required String idempotencyKey,
  }) async {
    calls.add('upload-url');
    uploadKeys.add(idempotencyKey);
    _maybeFail('upload-url');
    return _ticket(id: 'f${++tickets}', validSeconds: validSeconds);
  }

  @override
  Future<void> put(
    UploadTicket ticket,
    ReceiptImage image, {
    void Function(double fraction)? onProgress,
  }) async {
    calls.add('put:${ticket.fileId}');
    onProgress?.call(0.5);
    _maybeFail('put');
  }

  @override
  Future<void> complete(String fileId) async {
    calls.add('complete:$fileId');
    _maybeFail('complete');
  }

  @override
  Future<PaymentClaim> createClaim(
    String invoiceId, {
    required String receiptFileId,
    required int amount,
    String? note,
    required String idempotencyKey,
  }) async {
    calls.add('claim:$receiptFileId:$amount');
    claimKeys.add(idempotencyKey);
    _maybeFail('claim');
    onClaim?.call();
    return PaymentClaim(id: 'c1', status: ClaimStatus.pending, amount: amount);
  }
}

class _FakePicker implements ReceiptPicker {
  _FakePicker(this.image);
  ReceiptImage? image;
  @override
  Future<ReceiptImage?> pick() async => image;
}

ReceiptClaimCubit _cubit(_FakeReceipts repo, {ReceiptImage? image}) =>
    ReceiptClaimCubit(
      repo,
      _FakePicker(image ?? _img()),
      _invoiceId,
      now: () => _now,
    );

void main() {
  group('hợp đồng', () {
    test('model đọc đúng ví dụ của hợp đồng', () {
      final t = UploadTicket.fromJson(_example('UploadUrl'));
      expect(t.headers, {'Content-Type': 'image/jpeg'});
      expect(t.fileId, '019c0b30-0001-7b30-8c01-000000000001');
      final c = PaymentClaim.fromJson(_example('PaymentClaim'));
      expect(c.status, ClaimStatus.pending);
      expect(c.amount, 1400000);
      expect(ClaimStatus.fromWire('lạ'), ClaimStatus.pending);
    });

    test('trần và loại ảnh khớp mô tả hợp đồng', () {
      final desc =
          (_schemas['UploadUrlRequest']
                  as Map)['properties']['sizeBytes']['description']
              as String;
      expect(desc, contains('10 MB'));
      expect(receiptMaxBytes, 10000000);
      expect(
        ((_schemas['FilePurpose'] as Map)['description'] as String)
            .toLowerCase(),
        allOf(contains('jpeg'), contains('png'), contains('heic')),
      );
      expect(checkReceipt('image/png', receiptMaxBytes), isNull);
      expect(
        checkReceipt('image/png', receiptMaxBytes + 1),
        ReceiptIssue.tooLarge,
      );
      expect(checkReceipt('application/pdf', 10), ReceiptIssue.typeNotAllowed);
      expect(mimeFromFileName('A.HEIC'), 'image/heic');
    });

    test(
      'request đúng đường dẫn, thân và header; PUT đi Dio kho, không Bearer',
      () async {
        final api = _recording((o) {
          if (o.path == '/files/upload-urls') return _example('UploadUrl');
          if (o.path.endsWith('/payment-claims')) {
            return _example('PaymentClaim');
          }
          return _example('FileRecord');
        });
        final storage = _recording((_) => null);
        final repo = DioReceiptRepository(api.dio, storage.dio);
        final img = _img(size: 5);

        final t = await repo.requestUpload(
          _invoiceId,
          img,
          idempotencyKey: 'k1',
        );
        await repo.put(t, img);
        await repo.complete(t.fileId);
        await repo.createClaim(
          _invoiceId,
          receiptFileId: t.fileId,
          amount: 1400000,
          note: ' xong ',
          idempotencyKey: 'k2',
        );

        final up = api.requests[0];
        expect(up.method, 'POST');
        expect(up.headers['Idempotency-Key'], 'k1');
        expect(up.data, {
          'purpose': 'receipt',
          'entityId': _invoiceId,
          'fileName': 'bien-lai.jpg',
          'mimeType': 'image/jpeg',
          'sizeBytes': 5,
        });
        final req = (_schemas['UploadUrlRequest'] as Map)['required'] as List;
        expect((up.data as Map).keys, containsAll(req));

        final put = storage.requests.single;
        expect(put.method, 'PUT');
        expect(put.uri.host, 'files.example.invalid');
        expect(put.headers['Content-Type'], 'image/jpeg');
        expect(
          '${put.headers['content-length'] ?? put.headers['Content-Length']}',
          '5',
        );
        expect(
          put.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(api.requests.where((r) => r.method == 'PUT'), isEmpty);

        expect(api.requests[1].path, '/files/${t.fileId}/complete');
        final claim = api.requests[2];
        expect(claim.path, '/family/invoices/$_invoiceId/payment-claims');
        expect(claim.headers['Idempotency-Key'], 'k2');
        expect(claim.data, {
          'receiptFileId': t.fileId,
          'amount': 1400000,
          'note': 'xong',
        });
        final allowed =
            ((_schemas['CreatePaymentClaimRequest'] as Map)['properties']
                    as Map)
                .keys;
        expect(allowed, containsAll((claim.data as Map).keys));
      },
    );

    test('lỗi API đổi thành ApiException có mã', () async {
      final api = _recording(
        (_) => {'code': 'CONFLICT_STALE', 'message': 'x'},
        status: 409,
      );
      final repo = DioReceiptRepository(api.dio, api.dio);
      await expectLater(
        repo.complete('f'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.conflictStale,
          ),
        ),
      );
    });
  });

  group('ReceiptClaimCubit', () {
    test('chọn ảnh sai loại hoặc quá lớn: báo ngay, không gọi mạng', () async {
      final repo = _FakeReceipts();
      final big = _cubit(repo, image: _img(size: receiptMaxBytes + 1));
      await big.pickImage();
      expect(big.state.error, ClaimError.tooLarge);
      await big.submit(amount: 1000);
      final pdf = _cubit(repo, image: _img(mime: 'application/pdf'));
      await pdf.pickImage();
      await pdf.submit(amount: 1000);
      expect(pdf.state.error, ClaimError.typeNotAllowed);
      expect(repo.calls, isEmpty);
    });

    test('số tiền và ghi chú sai: không gọi mạng', () async {
      final repo = _FakeReceipts();
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 0);
      expect(c.state.error, ClaimError.amountInvalid);
      await c.submit(amount: 5, note: 'x' * 301);
      expect(c.state.error, ClaimError.noteTooLong);
      expect(repo.calls, isEmpty);
    });

    test('thành công: bốn bước theo thứ tự rồi done', () async {
      final repo = _FakeReceipts();
      final c = _cubit(repo);
      await c.pickImage();
      final stages = <ClaimStage?>[];
      final sub = c.stream.listen((s) => stages.add(s.stage));
      await c.submit(amount: 1400000);
      await sub.cancel();
      expect(repo.calls, [
        'upload-url',
        'put:f1',
        'complete:f1',
        'claim:f1:1400000',
      ]);
      expect(c.state.done, isTrue);
      expect(stages.whereType<ClaimStage>().toSet(), {
        ClaimStage.upload,
        ClaimStage.verify,
        ClaimStage.claim,
      });
    });

    test(
      'mất mạng ở bước tạo báo: thử lại không tải lại, không báo trùng',
      () async {
        final repo = _FakeReceipts()
          ..errors['claim'] = [const ApiException.network()];
        final c = _cubit(repo);
        await c.pickImage();
        await c.submit(amount: 1000);
        expect(c.state.error, ClaimError.offline);
        expect(c.state.image, isNotNull);
        await c.submit(amount: 1000);
        expect(c.state.done, isTrue);
        expect(repo.calls.where((x) => x == 'upload-url'), hasLength(1));
        expect(repo.calls.where((x) => x.startsWith('put')), hasLength(1));
        expect(repo.calls.where((x) => x.startsWith('complete')), hasLength(1));
        expect(repo.claimKeys, hasLength(2));
        expect(repo.claimKeys[0], repo.claimKeys[1]);
      },
    );

    test(
      'mất mạng ở PUT: thử lại dùng lại URL và khóa xin URL không đổi',
      () async {
        final repo = _FakeReceipts()
          ..errors['put'] = [const ApiException.network()];
        final c = _cubit(repo);
        await c.pickImage();
        await c.submit(amount: 1000);
        expect(c.state.error, ClaimError.offline);
        await c.submit(amount: 1000);
        expect(c.state.done, isTrue);
        expect(repo.calls.where((x) => x == 'upload-url'), hasLength(1));
        expect(repo.calls.where((x) => x == 'put:f1'), hasLength(2));
      },
    );

    test('mất mạng khi xin URL: thử lại dùng cùng Idempotency-Key', () async {
      final repo = _FakeReceipts()
        ..errors['upload-url'] = [const ApiException.network()];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      await c.submit(amount: 1000);
      expect(c.state.done, isTrue);
      expect(repo.uploadKeys, hasLength(2));
      expect(repo.uploadKeys[0], repo.uploadKeys[1]);
    });

    test('đổi số tiền giữa hai lần thử: khóa báo mới', () async {
      final repo = _FakeReceipts()
        ..errors['claim'] = [const ApiException.network()];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      await c.submit(amount: 2000);
      expect(repo.claimKeys[0], isNot(repo.claimKeys[1]));
    });

    test('URL hết hạn trước lần thử lại: xin URL mới, khóa mới', () async {
      final repo = _FakeReceipts()
        ..validSeconds = 10
        ..errors['complete'] = [const ApiException.network()];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.offline);
      await c.submit(amount: 1000);
      expect(c.state.done, isTrue);
      expect(repo.calls.where((x) => x == 'upload-url'), hasLength(2));
    });

    test('kho từ chối PUT (403): báo hết hạn, lần sau xin URL mới', () async {
      final repo = _FakeReceipts()..errors['put'] = [_http(403)];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.expired);
      await c.submit(amount: 1000);
      expect(c.state.done, isTrue);
      expect(repo.calls.where((x) => x == 'upload-url'), hasLength(2));
    });

    test('complete 409 (kho chưa có tệp): tải lại cùng URL', () async {
      final repo = _FakeReceipts()
        ..errors['complete'] = [_http(409, 'CONFLICT_STALE')];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.failed);
      await c.submit(amount: 1000);
      expect(c.state.done, isTrue);
      expect(repo.calls.where((x) => x.startsWith('put')), hasLength(2));
      expect(repo.calls.where((x) => x == 'upload-url'), hasLength(1));
    });

    test('server báo FILE_TOO_LARGE / FILE_TYPE_NOT_ALLOWED', () async {
      final repo = _FakeReceipts()
        ..errors['complete'] = [_http(422, 'FILE_TOO_LARGE')];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.tooLarge);
      repo.errors['upload-url'] = [_http(422, 'FILE_TYPE_NOT_ALLOWED')];
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.typeNotAllowed);
    });

    test('tạo báo 409: đã có lần báo chờ; hóa đơn không báo được', () async {
      final repo = _FakeReceipts()
        ..errors['claim'] = [_http(409, 'CONFLICT_STALE')];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.alreadyPending);
      expect(c.state.invoiceChanged, isTrue);

      final repo2 = _FakeReceipts()
        ..errors['claim'] = [_http(409, 'INVOICE_NOT_PAYABLE')];
      final c2 = _cubit(repo2);
      await c2.pickImage();
      await c2.submit(amount: 1000);
      expect(c2.state.error, ClaimError.notPayable);
    });

    test('lỗi không thử lại được thì bỏ khóa báo cũ', () async {
      final repo = _FakeReceipts()
        ..errors['claim'] = [_http(422, 'VALIDATION_FAILED')];
      final c = _cubit(repo);
      await c.pickImage();
      await c.submit(amount: 1000);
      expect(c.state.error, ClaimError.failed);
      await c.submit(amount: 1000);
      // Biên lai bị từ chối: tải tệp mới, khóa báo mới.
      expect(repo.claimKeys[0], isNot(repo.claimKeys[1]));
      expect(repo.calls.where((x) => x == 'upload-url'), hasLength(2));
    });
  });

  group('màn P03', () {
    testWidgets(
      'còn nợ: có nút báo chuyển khoản; chờ xác nhận: chỉ có thông báo',
      (tester) async {
        final inv = _FakeInvoices();
        await _pump(tester, inv, _FakeReceipts());
        expect(find.text('I have transferred'), findsOneWidget);

        inv.json = _json(status: 'pending_confirmation');
        await _pump(tester, inv, _FakeReceipts());
        expect(find.text('I have transferred'), findsNothing);
        expect(find.text('Awaiting confirmation'), findsOneWidget);
        expect(
          find.textContaining('You reported the transfer'),
          findsOneWidget,
        );
      },
    );

    testWidgets('chọn ảnh, gửi: hóa đơn hiện Chờ xác nhận', (tester) async {
      final inv = _FakeInvoices();
      final receipts = _FakeReceipts()
        ..onClaim = () => inv.json = _json(status: 'pending_confirmation');
      await _pump(tester, inv, receipts);
      await tester.tap(find.text('I have transferred'));
      await tester.pumpAndSettle();
      expect(find.text('Report a transfer'), findsOneWidget);
      // Số tiền mặc định là số còn nợ.
      expect(find.text('1500000'), findsOneWidget);

      await tester.tap(find.text('Choose receipt image'));
      await tester.pumpAndSettle();
      expect(find.text('Choose another image'), findsOneWidget);

      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(receipts.calls.last, 'claim:f1:1500000');
      expect(find.text('Report a transfer'), findsNothing);
      expect(find.text('Awaiting confirmation'), findsOneWidget);
      expect(find.text('I have transferred'), findsNothing);
    });

    testWidgets('ngoại tuyến: báo lỗi, giữ ảnh, Try again rồi xong', (
      tester,
    ) async {
      final inv = _FakeInvoices();
      final receipts = _FakeReceipts()
        ..errors['put'] = [const ApiException.network()]
        ..onClaim = () => inv.json = _json(status: 'pending_confirmation');
      await _pump(tester, inv, receipts, textScale: 1.3);
      await tester.tap(find.text('I have transferred'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose receipt image'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No network connection'), findsOneWidget);
      expect(find.text('Choose another image'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Awaiting confirmation'), findsOneWidget);
      expect(receipts.calls.where((x) => x == 'upload-url'), hasLength(1));
    });

    testWidgets('số tiền trống: báo ở ô, không gửi', (tester) async {
      final receipts = _FakeReceipts();
      await _pump(tester, _FakeInvoices(), receipts);
      await tester.tap(find.text('I have transferred'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose receipt image'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter the amount transferred, greater than 0.'),
        findsOneWidget,
      );
      expect(receipts.calls, isEmpty);
    });
  });
}

class _Recorded {
  _Recorded(this.dio, this.requests);
  final Dio dio;
  final List<RequestOptions> requests;
}

/// Dio ghi lại request, trả JSON do [respond] dựng (hoặc rỗng).
_Recorded _recording(
  Object? Function(RequestOptions) respond, {
  int status = 200,
}) {
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.invalid/v1'))
    ..httpClientAdapter = _Adapter(requests, respond, status);
  return _Recorded(dio, requests);
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.requests, this.respond, this.status);
  final List<RequestOptions> requests;
  final Object? Function(RequestOptions) respond;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = respond(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _json({String status = 'issued'}) => {
  'id': _invoiceId,
  'code': 'TH-25K7Q9',
  'status': status,
  'studentId': 'a',
  'studentName': 'Minh Anh',
  'teacherName': 'Cô Lan',
  'periodMonth': '2026-12-01',
  'totalAmount': 1500000,
  'paidAmount': 0,
  'carriedAmount': 0,
  'remainingAmount': 1500000,
  'dueDate': '2026-12-15',
  'issuedAt': '2026-12-01T01:00:00.000Z',
  'lines': [
    {
      'kind': 'monthly',
      'className': 'Toán 9A',
      'description': 'Học phí tháng 12',
      'amount': 1500000,
    },
  ],
  'payments': <Map<String, dynamic>>[],
  'transferNote': 'TH 25K7Q9',
  'qrPayload': 'vietqr-payload',
  'payout': {
    'bankBin': '970436',
    'bankName': 'Vietcombank',
    'accountNo': '0011223344',
    'accountName': 'NGUYEN VAN A',
  },
  'voidedAt': null,
};

class _FakeInvoices implements InvoiceRepository {
  Map<String, dynamic> json = _json();

  @override
  Future<InvoicePage> list({
    String? cursor,
    InvoiceStatus? status,
    String? studentId,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<InvoiceDetail> detail(String id) async => InvoiceDetail.fromJson(json);
}

/// P02 nằm trên đường vào P03 nên cần một kho giả; nội dung không quan trọng.
class _FamilyRepo implements FamilyRepository {
  @override
  Future<List<FamilyStudent>> students() async => const [
    FamilyStudent(id: 'a', fullName: 'Minh Anh', classes: []),
  ];

  @override
  Future<AttendanceWeek> attendance(String studentId, {DateTime? week}) =>
      throw const ApiException.network();
}

class _NoSaver implements QrImageSaver {
  @override
  Future<void> save(String qrPayload, {required String name}) async {}
}

Future<void> _pump(
  WidgetTester tester,
  _FakeInvoices invoices,
  _FakeReceipts receipts, {
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ParentController.instance
    ..familyRepository = _FamilyRepo()
    ..invoiceRepository = invoices
    ..qrImageSaver = _NoSaver()
    ..receiptRepository = receipts
    ..receiptPicker = _FakePicker(_img());
  addTearDown(() {
    c
      ..familyRepository = null
      ..invoiceRepository = null
      ..qrImageSaver = null
      ..receiptRepository = null
      ..receiptPicker = null;
  });
  final router = GoRouter(
    initialLocation: '${TeachHubRoutes.parentInvoices}/$_invoiceId',
    routes: c.routes(),
  );
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          ...MiniAppLocalizations.localizationsDelegates,
          TascoUiKitLocalizations.delegate,
        ],
        supportedLocales: MiniAppLocalizations.supportedLocales,
        theme: AppTheme.v1,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
