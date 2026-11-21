import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/fees/data/bank_bins.dart';
import 'package:teacher/features/fees/data/fee_models.dart';

void main() {
  test('formatVnd: 150000 → 150.000 đ', () {
    expect(formatVnd(150000), '150.000 đ');
    expect(formatVnd(999), '999 đ');
    expect(formatVnd(1000000000), '1.000.000.000 đ');
  });

  test('parseVnd: chỉ lấy chữ số; rỗng hoặc quá dài là null', () {
    expect(parseVnd('150.000 đ'), 150000);
    expect(parseVnd(''), isNull);
    expect(parseVnd('1234567890123'), isNull);
  });

  test(
    'VndInputFormatter: gõ từng số ra 150.000 đ, con trỏ sau chữ số cuối',
    () {
      const f = VndInputFormatter();
      var v = const TextEditingValue();
      for (final ch in '150000'.split('')) {
        v = f.formatEditUpdate(v, TextEditingValue(text: '${v.text}$ch'));
      }
      expect(v.text, '150.000 đ');
      expect(v.selection.baseOffset, '150.000'.length);
      // Xóa một số ở cuối: "150.00 đ" → 15.000 đ.
      final back = f.formatEditUpdate(
        v,
        const TextEditingValue(text: '150.00 đ'),
      );
      expect(back.text, '15.000 đ');
      expect(f.formatEditUpdate(v, const TextEditingValue(text: '')).text, '');
    },
  );

  test('FeeOverride rỗng gửi {}; có dữ liệu gửi đủ khóa', () {
    expect(const FeeOverride().toJson(), isEmpty);
    expect(const FeeOverride(discounts: []).isEmpty, isTrue);
    final j = const FeeOverride(
      feeAmount: 120000,
      chargeExcused: false,
      discounts: [
        FeeDiscount(
          kind: FeeDiscountKind.percent,
          description: ' Con thứ ',
          value: 10,
        ),
      ],
    ).toJson();
    expect(j['feeAmount'], 120000);
    expect(j['chargeExcused'], false);
    expect(j['chargeUnexcused'], isNull);
    expect(j['discounts'], [
      {'kind': 'percent', 'description': 'Con thứ', 'percent': 10},
    ]);
  });

  test('validateFeeOverride: giá, số đợt, khoản miễn giảm', () {
    final e = validateFeeOverride(
      const FeeOverride(
        feeAmount: 0,
        installments: 37,
        discounts: [
          FeeDiscount(
            kind: FeeDiscountKind.percent,
            description: '',
            value: 101,
          ),
          FeeDiscount(
            kind: FeeDiscountKind.amount,
            description: 'ok',
            value: 1,
          ),
        ],
      ),
    );
    expect(e, {
      'feeAmount': FeeOverrideError.amountRange,
      'installments': FeeOverrideError.installmentsRange,
      'discounts.0.description': FeeOverrideError.discountDescription,
      'discounts.0.value': FeeOverrideError.discountValue,
    });
    expect(validateFeeOverride(const FeeOverride()), isEmpty);
  });

  test(
    'validateClass: học phí cần số tiền 1..1 tỷ; số đợt > 1 chỉ trọn khóa',
    () {
      const base = ClassInput(
        name: 'A',
        subject: 'B',
        grade: 9,
        location: 'x',
        startDate: '2026-12-14',
      );
      ClassInput fee(FeeType t, int? amount, {int installments = 1}) =>
          ClassInput(
            name: base.name,
            subject: base.subject,
            grade: 9,
            location: 'x',
            startDate: base.startDate,
            endDate: '2027-06-30',
            feeType: t,
            feeAmount: amount,
            feeRules: FeeRules(installments: installments),
          );
      const rule = ScheduleRule(
        weekday: 2,
        startTime: '18:00',
        durationMin: 90,
      );
      expect(validateClass(base, const []), isEmpty);
      expect(
        validateClass(fee(FeeType.perSession, null), const [])['feeAmount'],
        ClassFieldError.feeAmountRequired,
      );
      expect(
        validateClass(
          fee(FeeType.perSession, 1000000001),
          const [],
        )['feeAmount'],
        ClassFieldError.feeAmountRange,
      );
      expect(
        validateClass(
          fee(FeeType.monthly, 1, installments: 2),
          const [],
        )['feeRules'],
        ClassFieldError.feeInstallments,
      );
      expect(
        validateClass(fee(FeeType.course, 1, installments: 36), const [rule]),
        isEmpty,
      );
      expect(
        validateClass(fee(FeeType.course, 1, installments: 37), const [
          rule,
        ])['feeRules'],
        ClassFieldError.feeInstallments,
      );
    },
  );

  test(
    'ClassInput.toPatchJson: học phí chỉ gửi khi withFee; tắt học phí gửi null',
    () {
      const on = ClassInput(
        feeType: FeeType.perSession,
        feeAmount: 150000,
        feeRules: FeeRules(chargeExcused: false),
      );
      expect(on.toPatchJson().containsKey('feeType'), isFalse);
      final j = on.toPatchJson(withFee: true);
      expect(j['feeType'], 'per_session');
      expect(j['feeAmount'], 150000);
      expect(j['feeRules'], {
        'chargeExcused': false,
        'chargeUnexcused': true,
        'deductCancelled': false,
        'installments': 1,
      });
      final off = const ClassInput().toPatchJson(withFee: true);
      expect(off['feeType'], isNull);
      expect(off['feeAmount'], isNull);
      expect(off.containsKey('feeRules'), isFalse);
    },
  );

  test('PayoutAccountInput.toString không lộ số tài khoản', () {
    const i = PayoutAccountInput(
      bankBin: '970436',
      accountNo: '0123456789',
      accountName: 'A',
    );
    expect(i.toString(), isNot(contains('0123456789')));
  });

  test('validatePayoutInput: BIN, số tài khoản 6–19 số, tên ≤ 50', () {
    PayoutAccountInput i({
      String bin = '970436',
      String no = '123456',
      String name = 'A',
    }) => PayoutAccountInput(bankBin: bin, accountNo: no, accountName: name);
    expect(validatePayoutInput(i(), accountNoRequired: true), isEmpty);
    expect(validatePayoutInput(i(bin: ''), accountNoRequired: true).keys, [
      'bankBin',
    ]);
    expect(
      validatePayoutInput(i(no: '12345'), accountNoRequired: true)['accountNo'],
      PayoutFieldError.accountNoFormat,
    );
    expect(
      validatePayoutInput(i(no: ''), accountNoRequired: true)['accountNo'],
      PayoutFieldError.required,
    );
    expect(validatePayoutInput(i(no: ''), accountNoRequired: false), isEmpty);
    expect(
      validatePayoutInput(
        i(name: 'x' * 51),
        accountNoRequired: true,
      )['accountName'],
      PayoutFieldError.nameTooLong,
    );
  });

  test('bảng BIN: 6 chữ số, không trùng', () {
    expect(banks.every((b) => RegExp(r'^\d{6}$').hasMatch(b.bin)), isTrue);
    expect(banks.map((b) => b.bin).toSet(), hasLength(banks.length));
    expect(bankName('970436'), 'Vietcombank');
    expect(bankName('000000'), isNull);
  });

  test(
    'S5: bản ghi giá riêng lạ không làm hỏng roster, nhãn vẫn theo feeOverride',
    () {
      final entry = RosterEntry.fromJson({
        'enrollmentId': 'e1',
        'studentId': 's1',
        'fullName': 'An',
        'studentStatus': 'active',
        'joinedOn': '2026-12-14',
        'guardians': <Object>[],
        'feeOverride': {
          'feeAmount': 120000,
          'chargeExcused': 'lạ',
          'discounts': [
            {'kind': 'bonus', 'description': 'x', 'bonus': 1},
            {'kind': 'percent', 'description': 'Con thứ hai', 'percent': 10},
          ],
        },
      });
      expect(entry.hasFeeOverride, isTrue);
      expect(entry.feeOverride!.feeAmount, 120000);
      expect(entry.feeOverride!.chargeExcused, isNull);
      expect(entry.feeOverride!.discounts.single.description, 'Con thứ hai');
    },
  );
}
