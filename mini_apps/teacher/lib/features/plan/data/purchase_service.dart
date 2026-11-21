import 'package:get_it/get_it.dart';

/// Kết quả mua Pro qua IAP.
enum PurchaseOutcome { purchased, cancelled, unavailable, failed }

/// Mua gói Pro qua App Store/Google Play. Kích hoạt do webhook RevenueCat phía
/// server, app chỉ tải lại `GET /plan-usage` sau khi [purchased].
abstract class PurchaseService {
  /// Giá hiển thị từ store (vd "250.000 ₫"); `null` thì ẩn giá.
  String? get priceLabel;

  Future<PurchaseOutcome> purchasePro();
}

PurchaseService purchaseService() => GetIt.I.isRegistered<PurchaseService>()
    ? GetIt.I<PurchaseService>()
    : const StubPurchaseService();

/// Bản tạm cho tới khi có sản phẩm IAP.
// TODO(#38): thay bằng bản RevenueCat (thêm purchases_flutter) khi C5 có sản phẩm.
class StubPurchaseService implements PurchaseService {
  const StubPurchaseService();

  @override
  String? get priceLabel => null;

  @override
  Future<PurchaseOutcome> purchasePro() async => PurchaseOutcome.unavailable;
}
