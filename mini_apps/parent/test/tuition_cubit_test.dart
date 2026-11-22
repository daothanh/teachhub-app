import 'package:flutter_test/flutter_test.dart';
import 'package:parent/features/invoice/cubit/tuition_cubit.dart';
import 'package:parent/features/invoice/data/invoice_models.dart';
import 'package:parent/features/invoice/data/invoice_repository.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class _Repo implements InvoiceRepository {
  bool fail = false;

  @override
  Future<InvoicePage> list({
    String? cursor,
    InvoiceStatus? status,
    String? studentId,
    int limit = 20,
  }) async {
    if (fail) throw const ApiException.network();
    return const InvoicePage(items: [], nextCursor: null);
  }

  @override
  Future<InvoiceDetail> detail(String id) => throw UnimplementedError();
}

void main() {
  test(
    'tải lỗi: failed (không ẩn im lặng); thử lại thành công thì hết lỗi',
    () async {
      final repo = _Repo()..fail = true;
      final c = TuitionCubit(repo, 'a');
      addTearDown(c.close);
      await c.load();
      expect(c.state.failed, isTrue);
      expect(c.state.loaded, isFalse);

      repo.fail = false;
      await c.load();
      expect(c.state.failed, isFalse);
      expect(c.state.loaded, isTrue);
    },
  );

  test('đã có số rồi làm mới lỗi: báo lỗi, không giữ số nợ cũ', () async {
    final repo = _Repo();
    final c = TuitionCubit(repo, 'a');
    addTearDown(c.close);
    await c.load();
    expect(c.state.loaded, isTrue);

    repo.fail = true;
    await c.load();
    expect(c.state.failed, isTrue);
    expect(c.state.loaded, isFalse);
  });
}
