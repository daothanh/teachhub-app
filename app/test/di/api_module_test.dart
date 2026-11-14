import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:app/core/config/app_env.dart';
import 'package:app/core/config/client_identity.dart';
import 'package:app/di/api_module.dart';
import 'package:app/di/const_key.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';

/// Answers each path from a script of statuses, the last one repeating, and
/// never answers a path in [hanging]. Every client in a test shares it: the
/// service client, the client the refresh goes through, and both retry clients.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._scripts, {this.hanging = const {}});

  final Map<String, List<int>> _scripts;
  final Set<String> hanging;

  /// The path of every request that reached the wire, in order.
  final List<String> calls = [];

  /// The `Authorization` header of every request that reached the wire.
  final List<Object?> authorizations = [];

  /// Completes when a request to a [hanging] path reaches the wire.
  final Completer<void> reachedHanging = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    calls.add(path);
    authorizations.add(options.headers['Authorization']);
    if (hanging.contains(path)) {
      reachedHanging.complete();
      return Completer<ResponseBody>().future;
    }
    final script = _scripts[path]!;
    final status = script.length > 1 ? script.removeAt(0) : script.single;
    return ResponseBody.fromString(
      jsonEncode({'token': 'fresh'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Counts calls instead of driving EasyLoading. The real manager clamps its
/// count at zero, which would hide an unpaired `hide()`.
class _CountingLoadingManager implements LoadingManager {
  int shows = 0;
  int hides = 0;

  int get pending => shows - hides;

  @override
  void show() => shows++;

  @override
  void hide() => hides++;

  @override
  void forceHide() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingLoadingManager loading;
  late AuthEventBus bus;
  late String? storedToken;

  setUp(() {
    loading = _CountingLoadingManager();
    bus = AuthEventBus();
    storedToken = 'stale';
  });
  tearDown(() => bus.dispose());

  /// A client wired the way `apiModule` wires every service client, with the
  /// shell's [serviceInterceptors] in the shell's order.
  Dio serviceClient(HttpClientAdapter adapter, AuthInterceptor auth) =>
      Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter
        ..interceptors.addAll(
          serviceInterceptors(
            loadingManager: loading,
            authInterceptor: auth,
            retryInterceptor: RetryInterceptor(
              retryClient: RetryInterceptor.buildRetryClient(adapter: adapter),
              baseDelay: Duration.zero,
            ),
          ),
        );

  /// The service client a test calls. Like the shell, the refresh runs on a
  /// second service client sharing the one [AuthInterceptor].
  Dio build(_ScriptedAdapter adapter, {Future<String?> Function()? readToken}) {
    late final Dio authClient;
    final refresher = TokenRefresher(
      refresh: () async {
        final response = await authClient.post<Map<String, dynamic>>(
          '/auth/refresh',
          options: Options(extra: {'requiresAuth': false}),
        );
        return storedToken = response.data!['token'] as String;
      },
      authEventBus: bus,
    );
    final auth = AuthInterceptor(
      readToken ?? () async => storedToken,
      () => refresher,
      retryClient: AuthInterceptor.buildRetryClient(adapter: adapter),
      authEventBus: bus,
    );
    authClient = serviceClient(adapter, auth);
    return serviceClient(adapter, auth);
  }

  void expectOverlayReleased() {
    expect(loading.shows, greaterThan(0), reason: 'the overlay never showed');
    expect(loading.pending, 0, reason: 'every show() needs exactly one hide()');
  }

  group('the loading overlay is released', () {
    test('after a plain success', () async {
      final adapter = _ScriptedAdapter({
        '/ok': [200],
      });

      final response = await build(adapter).get<dynamic>('/ok');

      expect(response.statusCode, 200);
      expectOverlayReleased();
    });

    test('after a 401 recovered by refresh and replay', () async {
      final adapter = _ScriptedAdapter({
        '/secure': [401, 200],
        '/auth/refresh': [200],
      });

      final response = await build(adapter).get<dynamic>('/secure');

      expect(response.statusCode, 200);
      expect(adapter.calls, ['/secure', '/auth/refresh', '/secure']);
      expectOverlayReleased();
    });

    test('after a transient failure recovered by a retry', () async {
      final adapter = _ScriptedAdapter({
        '/flaky': [503, 200],
      });

      final response = await build(adapter).get<dynamic>('/flaky');

      expect(response.statusCode, 200);
      expect(adapter.calls, ['/flaky', '/flaky']);
      expectOverlayReleased();
    });

    test('after a failure that outlasts every retry', () async {
      final adapter = _ScriptedAdapter({
        '/down': [503],
      });

      await expectLater(
        build(adapter).get<dynamic>('/down'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, hasLength(4), reason: 'the call and 3 retries');
      expectOverlayReleased();
    });

    test('after a 401 the refresh cannot recover', () async {
      final events = <AuthEvent>[];
      bus.stream.listen(events.add);
      final adapter = _ScriptedAdapter({
        '/secure': [401],
        '/auth/refresh': [401],
      });

      await expectLater(
        build(adapter).get<dynamic>('/secure'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, [AuthEvent.sessionExpired]);
      expectOverlayReleased();
    });

    test('after the token read fails before sending', () async {
      final adapter = _ScriptedAdapter({});

      await expectLater(
        build(
          adapter,
          readToken: () async => throw StateError('keystore locked'),
        ).get<dynamic>('/secure'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, isEmpty);
      expectOverlayReleased();
    });

    test('after a cancellation on the wire', () async {
      final adapter = _ScriptedAdapter({}, hanging: {'/slow'});
      final cancel = CancelToken();
      final request = build(adapter).get<dynamic>('/slow', cancelToken: cancel);
      await adapter.reachedHanging.future;

      cancel.cancel();

      await expectLater(
        request,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expectOverlayReleased();
    });
  });

  // The stack above only matters if apiModule installs it: these are the
  // clients the app resolves.
  group('apiModule', () {
    late GetIt getIt;

    setUp(() async {
      final env = AppEnv();
      await env.init(Env.production);
      dotenv.testLoad(
        fileInput: [
          'AUTH_URL=https://auth.test',
          'CRM_URL=https://crm.test',
          'HRM_URL=https://hrm.test',
          'TICKET_URL=https://ticket.test',
          'CERT_PINS=${'ab' * 32}',
        ].join('\n'),
      );
      final tokenStore = TokenStore(InMemoryKeyValueStore());
      await tokenStore.saveTokens(accessToken: 'stored');
      getIt = GetIt.asNewInstance()
        ..registerSingleton<AppEnv>(env)
        ..registerSingleton<ClientIdentity>(
          const ClientIdentity(
            appVersion: '1.2.3',
            deviceId: 'device',
            deviceType: 'ios',
            deviceName: 'iPhone',
            clientSource: 'app_Test',
          ),
        )
        ..registerSingleton<LoadingManager>(loading)
        ..registerSingleton<AuthEventBus>(bus)
        ..registerSingleton<TokenStore>(tokenStore);
      await apiModule(getIt);
    });
    tearDown(() => dotenv.clean());

    const clients = {
      DiKey.authDio: 'https://auth.test',
      DiKey.crmDio: 'https://crm.test',
      DiKey.hrmDio: 'https://hrm.test',
      DiKey.ticketDio: 'https://ticket.test',
    };

    test('installs the loading interceptor ahead of auth and retry', () {
      final pinned = getIt<Dio>(instanceName: DiKey.authDio).httpClientAdapter;
      for (final MapEntry(key: name, value: baseUrl) in clients.entries) {
        final dio = getIt<Dio>(instanceName: name);

        expect(dio.options.baseUrl, baseUrl, reason: name);
        expect(
          dio.httpClientAdapter,
          same(pinned),
          reason: '$name shares the one pinned adapter',
        );
        expect(
          dio.interceptors.map((i) => i.runtimeType),
          containsAllInOrder(<Type>[
            ErrorInterceptor,
            AuthInterceptor,
            RetryInterceptor,
            LoggingInterceptor,
          ]),
          reason: name,
        );
        expect(
          dio.interceptors.whereType<AuthInterceptor>().single,
          same(getIt<AuthInterceptor>()),
          reason: '$name shares the one AuthInterceptor',
        );
      }
      expect(getIt<TokenRefresher>(), isA<TokenRefresher>());
    });

    test(
      'sends the stored token and drives the registered LoadingManager',
      () async {
        final adapter = _ScriptedAdapter({
          '/ok': [200],
        });
        final dio = getIt<Dio>(instanceName: DiKey.authDio)
          ..httpClientAdapter = adapter;

        await dio.get<dynamic>('/ok');

        expect(adapter.authorizations, ['Bearer stored']);
        expectOverlayReleased();
      },
    );
  });
}
