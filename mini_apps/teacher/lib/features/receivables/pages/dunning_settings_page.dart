import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../billing/widgets/billing_error_text.dart';
import '../cubit/dunning_settings_cubit.dart';
import '../data/receivables_repository.dart';
import '../widgets/dunning_labels.dart';

/// Cài đặt nhắc nợ của tenant (US-7.5 AC3–AC4): bật/tắt, sửa mốc nhắc, lưu một
/// lần, xem trước mẫu tin của từng mốc.
class DunningSettingsPage extends StatelessWidget {
  const DunningSettingsPage({super.key, this.repository});
  final ReceivablesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DunningSettingsCubit(repository ?? receivablesRepository())..load(),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<DunningSettingsCubit>();
    return BlocConsumer<DunningSettingsCubit, DunningSettingsState>(
      listenWhen: (a, b) => b.justSaved && !a.justSaved,
      listener: (context, _) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dunningSaved))),
      builder: (context, s) => Scaffold(
        appBar: AppBar(title: Text(l10n.dunningSettingsTitle)),
        body: switch (s.load) {
          BillingLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BillingLoad.failure => AppEmptyState(
            message: s.error == null
                ? l10n.billingLoadFailed
                : billingErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready => _Body(state: s),
        },
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.state});
  final DunningSettingsState state;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _input = TextEditingController();
  bool _notNumber = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    // Dấu trừ thật (−) cũng được nhận để khớp chữ hiển thị.
    final v = int.tryParse(_input.text.trim().replaceAll('−', '-'));
    setState(() => _notNumber = v == null);
    if (v == null) return;
    final cubit = context.read<DunningSettingsCubit>()..addOffset(v);
    if (cubit.state.offsetError == null) _input.clear();
  }

  String? _offsetError(MiniAppLocalizations l10n, DunningSettingsState s) {
    if (_notNumber) return l10n.dunningOffsetErrNumber;
    return switch (s.offsetError) {
      OffsetError.range => l10n.dunningOffsetErrRange,
      OffsetError.duplicate => l10n.dunningOffsetErrDuplicate,
      OffsetError.tooMany => l10n.dunningOffsetErrTooMany,
      OffsetError.tooFew => l10n.dunningOffsetErrTooFew,
      null when s.serverErrors.isNotEmpty => s.serverErrors.join('\n'),
      null => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<DunningSettingsCubit>();
    final s = widget.state;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (s.error != null) ...[
          AppBanner(
            tone: AppStatusTone.error,
            description: billingErrorText(l10n, s.error!),
            fullWidth: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.dunningSettingsEnabled),
          subtitle: Text(l10n.dunningSettingsEnabledHint),
          value: s.enabled,
          onChanged: s.saving ? null : cubit.setEnabled,
        ),
        const Divider(height: AppSpacing.xl),
        Text(l10n.dunningSettingsOffsets, style: text.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.dunningSettingsOffsetsHint, style: text.bodySmall),
        for (final d in s.offsets)
          _OffsetRow(
            days: d,
            selected: s.preview?.offsetDays == d,
            onPreview: () => cubit.showPreview(d),
            onRemove: () => cubit.removeOffset(d),
          ),
        if (s.preview != null) _PreviewCard(preview: s.preview!),
        const SizedBox(height: AppSpacing.md),
        AppInput(
          controller: _input,
          label: l10n.dunningOffsetInput,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[-−0-9]')),
          ],
          errorText: _offsetError(l10n, s),
          onSubmitted: (_) => _add(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            AppButton(
              label: l10n.dunningOffsetAdd,
              variant: AppButtonVariant.outlinePrimary,
              onPressed: _add,
            ),
            TextButton(
              onPressed: cubit.resetOffsets,
              child: Text(l10n.dunningOffsetReset),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.dunningSave,
          width: double.infinity,
          disabled: s.saving || !s.dirty,
          onPressed: cubit.save,
        ),
      ],
    );
  }
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.days,
    required this.selected,
    required this.onPreview,
    required this.onRemove,
  });
  final int days;
  final bool selected;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final label = dunningOffsetLabel(l10n, days);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : null,
              ),
            ),
          ),
          TextButton(
            onPressed: onPreview,
            child: Text(l10n.dunningOffsetPreview),
          ),
          IconButton(
            tooltip: '${l10n.dunningOffsetRemove}: $label',
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
  final DunningPreviewState preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final p = preview.preview;
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dunningPreviewTitle, style: text.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            if (preview.failed)
              Text(l10n.dunningPreviewFailed)
            else if (p == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(p.title, style: text.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(p.body, style: text.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.dunningPreviewNote, style: text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
