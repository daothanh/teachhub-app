import 'package:flutter/material.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../fees/data/fee_models.dart' show formatVnd;
import '../data/report_models.dart';

/// Biểu đồ cột doanh thu đã thu 12 tháng (T12a, US-8.2 AC1), vẽ bằng widget
/// (repo chưa có gói biểu đồ). Cột tỷ lệ với tháng cao nhất; số âm (hợp đồng không
/// còn sinh, giữ cho an toàn) vẽ như 0, số thật ở nhãn đọc màn hình. Chạm cột để chọn tháng.
class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({
    super.key,
    required this.months,
    required this.selected,
    required this.onSelect,
  });
  final List<MonthRevenue> months;

  /// `YYYY-MM` đang chọn.
  final String? selected;
  final ValueChanged<String> onSelect;

  static const _plotHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final scheme = Theme.of(context).colorScheme;
    final peak = months.fold<int>(
      0,
      (m, e) => e.collectedAmount > m ? e.collectedAmount : m,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final m in months)
          Expanded(
            child: Semantics(
              button: true,
              selected: m.month == selected,
              label: l10n.reportsChartBar(
                parseYearMonth(m.month).month,
                formatVnd(m.collectedAmount),
              ),
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('bar-${m.month}'),
                onTap: () => onSelect(m.month),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: _plotHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: m.collectedAmount > 0 && peak > 0
                                ? (_plotHeight * m.collectedAmount / peak)
                                      .clamp(4.0, _plotHeight)
                                : 2,
                            decoration: BoxDecoration(
                              color: m.month == selected
                                  ? scheme.primary
                                  : scheme.primary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${parseYearMonth(m.month).month}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: m.month == selected
                                    ? FontWeight.w700
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
