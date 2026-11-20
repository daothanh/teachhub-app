import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../data/class_models.dart';
import 'read_only_field.dart';

/// Soạn quy tắc lặp hằng tuần (US-2.1): nhiều thứ, giờ bắt đầu, thời lượng.
/// Mỗi quy tắc là một thẻ xếp dọc nên chữ 130% không vỡ hàng.
class ScheduleRulesEditor extends StatelessWidget {
  const ScheduleRulesEditor({
    super.key,
    required this.rules,
    required this.onChanged,
    this.error,
  });
  final List<ScheduleRule> rules;
  final ValueChanged<List<ScheduleRule>> onChanged;
  final String? error;

  static const maxRules = 14;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.classesRulesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (i, r) in rules.indexed)
          _RuleCard(
            number: i + 1,
            key: ValueKey(i),
            rule: r,
            onChanged: (n) => onChanged([...rules]..[i] = n),
            onRemove: () => onChanged([...rules]..removeAt(i)),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (rules.length < maxRules)
          AppButton(
            label: l10n.classesRuleAdd,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            onPressed: () => onChanged([
              ...rules,
              const ScheduleRule(
                weekday: 1,
                startTime: '18:00',
                durationMin: 90,
              ),
            ]),
          ),
      ],
    );
  }
}

class _RuleCard extends StatefulWidget {
  const _RuleCard({
    super.key,
    required this.number,
    required this.rule,
    required this.onChanged,
    required this.onRemove,
  });
  final int number;
  final ScheduleRule rule;
  final ValueChanged<ScheduleRule> onChanged;
  final VoidCallback onRemove;

  @override
  State<_RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<_RuleCard> {
  late final _duration = TextEditingController(
    text: '${widget.rule.durationMin}',
  );

  // Xóa một thẻ giữa danh sách làm thẻ sau dồn lên: đồng bộ lại ô thời lượng.
  @override
  void didUpdateWidget(_RuleCard old) {
    super.didUpdateWidget(old);
    if (_duration.text.isNotEmpty &&
        int.tryParse(_duration.text) != widget.rule.durationMin) {
      _duration.text = '${widget.rule.durationMin}';
    }
  }

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  ScheduleRule _with({int? weekday, String? startTime, int? durationMin}) =>
      ScheduleRule(
        weekday: weekday ?? widget.rule.weekday,
        startTime: startTime ?? widget.rule.startTime,
        durationMin: durationMin ?? widget.rule.durationMin,
      );

  Future<void> _pickTime() async {
    final p = widget.rule.startTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    widget.onChanged(
      _with(
        startTime:
            '${picked.hour.toString().padLeft(2, '0')}:'
            '${picked.minute.toString().padLeft(2, '0')}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.classesRuleN(widget.number),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var d = 1; d <= 7; d++)
                  AppChoiceChip(
                    label: l10n.classesWeekdayShort('$d'),
                    selected: widget.rule.weekday == d,
                    semanticLabel:
                        '${l10n.classesRuleN(widget.number)}, ${l10n.classesWeekday('$d')}',
                    onTap: () => widget.onChanged(_with(weekday: d)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ReadOnlyField(
              text: widget.rule.startTime,
              label: l10n.classesRuleTime,
              onTap: _pickTime,
              suffix: const Icon(Icons.schedule),
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _duration,
              label: l10n.classesRuleDuration,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                // Ô trống = 0 để kiểm tra báo lỗi thời lượng, không giữ số cũ.
                widget.onChanged(_with(durationMin: int.tryParse(v) ?? 0));
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              // Nhãn riêng từng buổi để trình đọc màn hình phân biệt các nút Xóa.
              child: Semantics(
                label: l10n.classesRuleRemoveN(widget.number),
                button: true,
                excludeSemantics: true,
                onTap: widget.onRemove,
                child: TextButton(
                  onPressed: widget.onRemove,
                  child: Text(l10n.classesRuleRemove),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
