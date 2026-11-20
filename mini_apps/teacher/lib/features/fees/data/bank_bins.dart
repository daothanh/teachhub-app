/// Ngân hàng chọn được khi thêm tài khoản nhận tiền.
class Bank {
  const Bank(this.bin, this.name);
  final String bin;
  final String name;
}

// shortcut: danh sách BIN NAPAS tạm trong code app, chờ chốt nơi đặt bảng BIN
// (server giữ hay client giữ, xem CHANGELOG hợp đồng Sprint 5 mục "Chờ chốt").
const banks = <Bank>[
  Bank('970436', 'Vietcombank'),
  Bank('970415', 'VietinBank'),
  Bank('970418', 'BIDV'),
  Bank('970405', 'Agribank'),
  Bank('970407', 'Techcombank'),
  Bank('970422', 'MB Bank'),
  Bank('970416', 'ACB'),
  Bank('970432', 'VPBank'),
  Bank('970403', 'Sacombank'),
  Bank('970423', 'TPBank'),
  Bank('970441', 'VIB'),
  Bank('970437', 'HDBank'),
  Bank('970443', 'SHB'),
  Bank('970426', 'MSB'),
  Bank('970448', 'OCB'),
  Bank('970440', 'SeABank'),
  Bank('970431', 'Eximbank'),
  Bank('970449', 'LPBank'),
  Bank('970428', 'Nam A Bank'),
  Bank('970409', 'Bac A Bank'),
  Bank('970454', 'Viet Capital Bank'),
  Bank('970429', 'SCB'),
  Bank('970425', 'ABBank'),
  Bank('970412', 'PVcomBank'),
  Bank('970419', 'NCB'),
];

/// Tên ngân hàng theo BIN; BIN lạ trả `null`.
String? bankName(String bin) =>
    banks.where((b) => b.bin == bin).firstOrNull?.name;
