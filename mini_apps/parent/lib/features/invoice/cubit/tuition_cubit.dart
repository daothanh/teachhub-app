import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invoice_repository.dart';

/// Số hóa đơn chưa thanh toán và tổng số còn nợ của một con (card học phí ở P02).
class TuitionState extends Equatable {
  const TuitionState({
    this.loaded = false,
    this.count = 0,
    this.total = 0,
    this.hasMore = false,
  });

  /// `false` khi đang tải hoặc lỗi: card ẩn, không chặn phần còn lại của P02.
  final bool loaded;
  final int count;
  final int total;

  /// Còn trang sau: [count] và [total] mới là phần đã đọc, hiện "N+".
  final bool hasMore;

  @override
  List<Object?> get props => [loaded, count, total, hasMore];
}

class TuitionCubit extends Cubit<TuitionState> {
  TuitionCubit(this._repo, this.studentId) : super(const TuitionState());

  final InvoiceRepository _repo;
  final String studentId;

  Future<void> load() async {
    try {
      // shortcut: chỉ đọc trang đầu 50 hóa đơn mới nhất của con, hiện "N+"
      // khi còn trang sau; "chưa đóng xong" vì tổng là totalAmount, chưa trừ
      // phần đã trả (nay đã trừ: tổng là Σ còn nợ). Sửa khi có endpoint tổng hợp.
      final page = await _repo.list(studentId: studentId, limit: 50);
      if (isClosed) return;
      final unpaid = page.items.where((i) => i.status.isUnpaid);
      emit(
        TuitionState(
          loaded: true,
          count: unpaid.length,
          total: unpaid.fold(0, (sum, i) => sum + i.remainingAmount),
          hasMore: page.nextCursor != null,
        ),
      );
    } catch (_) {
      // Card học phí là phần phụ: lỗi thì ẩn.
    }
  }
}
