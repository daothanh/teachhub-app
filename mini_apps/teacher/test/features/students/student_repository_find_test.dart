import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/students/data/student_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// 750 học viên, 100 mỗi trang: học viên cuối nằm ở trang 8 (vượt mức 500 cũ).
class _PagedAdapter implements HttpClientAdapter {
  _PagedAdapter(this.total);
  final int total;
  final pages = <int>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final page = options.queryParameters['page'] as int;
    pages.add(page);
    final from = (page - 1) * 100;
    final to = (from + 100).clamp(0, total);
    return ResponseBody.fromString(
      jsonEncode({
        'items': [
          for (var i = from; i < to; i++) {'id': 's$i', 'fullName': 'HS $i'},
        ],
        'total': total,
        'page': page,
        'pageSize': 100,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  DioStudentRepository repoWith(_PagedAdapter a) => DioStudentRepository(
    Dio(BaseOptions(baseUrl: 'http://x/v1'))..httpClientAdapter = a,
  );

  test('find duyệt hết các trang, không dừng ở 500', () async {
    final a = _PagedAdapter(750);
    final s = await repoWith(a).find('s740', classId: 'c1');
    expect(s.id, 's740');
    expect(a.pages, [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('find không thấy: hết danh sách thì 404', () async {
    final a = _PagedAdapter(250);
    final e = await repoWith(a)
        .find('nope', classId: 'c1')
        .then<Object>((_) => 'ok', onError: (Object e) => e);
    expect(e, isA<ApiException>());
    expect((e as ApiException).code, ApiErrorCode.notFound);
    expect(a.pages, [1, 2, 3]);
  });
}
