import 'dart:async';
import 'dart:io';

import 'package:app/core/background/background_sync.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/teacher.dart';

class _Capture implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Future<bool> run({
    String task = outboxSyncTask,
    Future<bool> Function()? hasSession,
    Future<BackgroundSyncOutcome> Function()? sync,
    List<String>? calls,
    bool isIOS = false,
  }) => runBackgroundTask(
    task: task,
    hasSession: hasSession ?? () async => true,
    sync:
        sync ??
        () async {
          calls?.add('sync');
          return BackgroundSyncOutcome.done;
        },
    cancel: () async => calls?.add('cancel'),
    reschedule: () async => calls?.add('reschedule'),
    isIOS: isIOS,
  );

  group('runBackgroundTask', () {
    test('chưa đăng nhập: không đồng bộ, không xin thử lại', () async {
      final calls = <String>[];
      expect(await run(hasSession: () async => false, calls: calls), isTrue);
      expect(calls, isEmpty);
    });

    test('đọc Keychain lỗi (máy khóa): bỏ lượt, xin thử lại', () async {
      final calls = <String>[];
      expect(
        await run(
          hasSession: () async => throw StateError('locked'),
          calls: calls,
        ),
        isFalse,
      );
      expect(calls, isEmpty);
    });

    test(
      'done → true; retry → false (iOS hẹn lại, Android để OS thử)',
      () async {
        expect(await run(sync: () async => BackgroundSyncOutcome.done), isTrue);
        var calls = <String>[];
        expect(
          await run(
            sync: () async => BackgroundSyncOutcome.retry,
            calls: calls,
          ),
          isFalse,
        );
        expect(calls, isEmpty);
        calls = [];
        await run(
          sync: () async {
            calls.add('sync');
            return BackgroundSyncOutcome.retry;
          },
          calls: calls,
          isIOS: true,
        );
        expect(calls, ['sync', 'reschedule']);
      },
    );

    test('notAllowed → hủy lịch', () async {
      final calls = <String>[];
      expect(
        await run(
          sync: () async => BackgroundSyncOutcome.notAllowed,
          calls: calls,
        ),
        isTrue,
      );
      expect(calls, ['cancel']);
    });

    test('tác vụ lạ bị bỏ qua', () async {
      var checked = false;
      expect(
        await run(
          task: 'iOSPerformFetch',
          hasSession: () async => checked = true,
        ),
        isTrue,
      );
      expect(checked, isFalse);
    });
  });

  group('buildBackgroundDio', () {
    Dio build({Set<String> pins = const {'aa'}, bool requirePins = true}) =>
        buildBackgroundDio(
          apiUrl: 'https://api.test/v1',
          pins: pins,
          requirePins: requirePins,
          accessToken: () async => 'tok',
          clientInfo: 'teachhub-app/1 (test)',
        );

    test('có adapter pin khi có pin', () {
      expect(build().httpClientAdapter, isNot(isA<_Capture>()));
      expect(
        build().httpClientAdapter.runtimeType,
        CertificatePinning.adapter(allowedSha256: {'aa'}).runtimeType,
      );
    });

    test('staging/production thiếu pin: fail-closed', () {
      expect(() => build(pins: {}), throwsStateError);
      // development được phép không pin
      expect(build(pins: {}, requirePins: false), isA<Dio>());
    });

    test('gửi Bearer; 401 không gọi refresh, không đụng token', () async {
      final tokens = TokenStore(InMemoryKeyValueStore());
      await tokens.saveTokens(accessToken: 'tok', refreshToken: 'refresh');
      final dio = build(requirePins: false, pins: {});
      final adapter = _Capture()..status = 401;
      dio.httpClientAdapter = adapter;
      await expectLater(dio.get<void>('/x'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(1)); // không gửi lại sau refresh
      expect(adapter.requests.single.headers['Authorization'], 'Bearer tok');
      expect(
        dio.interceptors.whereType<AuthInterceptor>(),
        isEmpty,
        reason: 'đường nền không có interceptor làm mới token',
      );
      expect(await tokens.getRefreshToken(), 'refresh');
    });
  });

  group('syncOutboxFromInput', () {
    Future<BackgroundSyncOutcome> sync(
      Map<String, dynamic> input, {
      required List<String> calls,
    }) => syncOutboxFromInput(
      input,
      keys: InMemoryKeyValueStore(),
      accessToken: () async => 'tok',
      userId: () async => 'u',
      directory: () async => Directory.systemTemp,
      clientInfo: () async => 'c',
      runner:
          ({
            required dio,
            required keys,
            required directory,
            required currentUserId,
          }) async {
            calls.add('run:${dio.options.baseUrl}');
            return BackgroundSyncOutcome.done;
          },
    );

    test('thiếu apiUrl: không chạy', () async {
      final calls = <String>[];
      expect(await sync({}, calls: calls), BackgroundSyncOutcome.done);
      expect(calls, isEmpty);
    });

    test('production thiếu pin: không chạy (fail-closed)', () async {
      final calls = <String>[];
      await sync(
        backgroundInput(
          apiUrl: 'https://api.test/v1',
          pins: {},
          requirePins: true,
        ),
        calls: calls,
      );
      expect(calls, isEmpty);
    });

    test('đủ cấu hình: chạy runner với base URL từ inputData', () async {
      final calls = <String>[];
      await sync(
        backgroundInput(
          apiUrl: 'https://api.test/v1',
          pins: {'aa'},
          requirePins: true,
        ),
        calls: calls,
      );
      expect(calls, ['run:https://api.test/v1']);
    });
  });

  test(
    'chỉ hủy lịch khi vừa mất phiên hoặc kiểm phiên xong không có phiên',
    () {
      bool c(bool was, bool checked) => shouldCancelBackgroundSync(
        wasAuthenticated: was,
        isAuthenticated: false,
        sessionChecked: checked,
      );
      expect(c(false, false), isFalse); // khởi động nguội: đang kiểm phiên
      expect(c(true, false), isTrue); // vừa đăng xuất
      expect(c(false, true), isTrue); // kiểm xong, không có phiên
      expect(
        shouldCancelBackgroundSync(
          wasAuthenticated: true,
          isAuthenticated: true,
          sessionChecked: true,
        ),
        isFalse,
      );
    },
  );
}
