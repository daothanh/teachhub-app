import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/invoice_repository.dart';

/// Số hóa đơn chưa thanh toán và tổng tiền của một con (card học phí ở P02).
class TuitionState extends Equatable {
  const TuitionState({this.loaded = false, this.count = 0, this.total = 0});

  /// `false` khi đang tải hoặc lỗi: card ẩn, không chặn phần còn lại của P02.
  final bool loaded;
  final int count;
  final int total;

  @override
  List<Object?> get props => [loaded, count, total];
}

class TuitionCubit extends Cubit<TuitionState> {
  TuitionCubit(this._repo, this.studentId) : super(const TuitionState());

  final InvoiceRepository _repo;
  final String studentId;

  Future<void> load() async {
    try {
      // shortcut: chỉ đọc trang đầu 50 hóa đơn mới nhất của con; thêm
      // endpoint tổng hợp khi một con có hơn 50 hóa đơn cùng lúc.
      final page = await _repo.list(studentId: studentId, limit: 50);
      if (isClosed) return;
      final unpaid = page.items.where((i) => i.status.isUnpaid);
      emit(
        TuitionState(
          loaded: true,
          count: unpaid.length,
          total: unpaid.fold(0, (sum, i) => sum + i.totalAmount),
        ),
      );
    } catch (_) {
      // Card học phí là phần phụ: lỗi thì ẩn.
    }
  }
}
