import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invoice_models.dart';
import '../data/invoice_repository.dart';

/// Số hóa đơn chưa thanh toán và tổng số còn nợ của một con (card học phí ở P02).
class TuitionState extends Equatable {
  const TuitionState({
    this.loaded = false,
    this.count = 0,
    this.total = 0,
    this.failed = false,
  });

  /// `false` khi đang tải hoặc lỗi; đang tải thì card ẩn, không chặn P02.
  final bool loaded;

  /// Tải lỗi: card báo lỗi kèm nút thử lại, không ẩn (ẩn dễ hiểu nhầm là hết nợ).
  final bool failed;
  final int count;
  final int total;

  @override
  List<Object?> get props => [loaded, count, total, failed];
}

/// Trần số trang khi cộng nợ (50 hóa đơn/trang).
const maxTuitionPages = 20;

class TuitionCubit extends Cubit<TuitionState> {
  TuitionCubit(this._repo, this.studentId) : super(const TuitionState());

  final InvoiceRepository _repo;
  final String studentId;

  Future<void> load() async {
    try {
      // Đọc hết các trang: tổng nợ chỉ đúng khi tính đủ mọi hóa đơn của con.
      final unpaid = <InvoiceSummary>[];
      String? cursor;
      var pages = 0;
      do {
        // Mỗi con chỉ vài chục hóa đơn; chặn vòng lặp khi con trỏ server lỗi.
        if (++pages > maxTuitionPages) {
          throw StateError('quá $maxTuitionPages trang hóa đơn');
        }
        final page = await _repo.list(
          studentId: studentId,
          cursor: cursor,
          limit: 50,
        );
        if (isClosed) return;
        // Hóa đơn đã chuyển hết nợ sang kỳ sau (còn nợ 0) không tính: khoản đó
        // nằm ở hóa đơn kỳ sau, tránh cộng hai lần.
        unpaid.addAll(
          page.items.where((i) => i.status.isUnpaid && i.remainingAmount > 0),
        );
        cursor = page.nextCursor;
      } while (cursor != null);
      emit(
        TuitionState(
          loaded: true,
          count: unpaid.length,
          total: unpaid.fold(0, (sum, i) => sum + i.remainingAmount),
        ),
      );
    } catch (_) {
      // Số cũ có thể đã sai (vừa đóng tiền): báo lỗi thay vì giữ số cũ.
      if (!isClosed) emit(const TuitionState(failed: true));
    }
  }
}
