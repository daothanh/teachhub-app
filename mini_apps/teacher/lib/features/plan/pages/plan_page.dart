import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../../classes/widgets/classes_error_text.dart';
import '../cubit/plan_cubit.dart';
import '../data/plan_models.dart';
import '../data/plan_repository.dart';
import '../data/purchase_service.dart';

/// Trang web thanh toán Pro (chuyển khoản chỉ ở web, R6).
final proWebUri = Uri.parse('https://app.dayhoc.app/subscription');

Future<bool> _openExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// T14 (US-0.7, US-0.8): gói hiện tại, hạn, mức dùng so với giới hạn Free,
/// tính năng Pro, dùng thử 14 ngày, mua Pro qua IAP và nút mở trang web.
class PlanPage extends StatelessWidget {
  const PlanPage({
    super.key,
    this.repository,
    this.purchase,
    this.openUrl = _openExternal,
  });
  final PlanRepository? repository;
  final PurchaseService? purchase;

  /// Mở trang web ngoài app; `false` khi không mở được.
  final Future<bool> Function(Uri) openUrl;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        PlanCubit(repository ?? planRepository(), purchase ?? purchaseService())
          ..load(),
    child: _View(openUrl: openUrl),
  );
}

class _View extends StatelessWidget {
  const _View({required this.openUrl});
  final Future<bool> Function(Uri) openUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<PlanCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.planTitle)),
      body: BlocConsumer<PlanCubit, PlanState>(
        listenWhen: (a, b) =>
            (b.notice != null && a.notice != b.notice) ||
            (b.actionError != null && a.actionError != b.actionError),
        listener: (context, s) {
          final text = switch (s.notice) {
            PlanNotice.trialStarted => l10n.planTrialStarted(
              s.usage?.daysLeft ?? 14,
            ),
            PlanNotice.purchasePending => l10n.planBuyPending,
            PlanNotice.purchaseUnavailable => l10n.planBuyUnavailable,
            PlanNotice.purchaseFailed => l10n.planBuyFailed,
            null => switch (s.actionError?.code) {
              ApiErrorCode.trialAlreadyUsed => l10n.planErrTrialUsed,
              ApiErrorCode.conflictStale => l10n.planErrBusy,
              _ =>
                s.actionError == null
                    ? null
                    : classesErrorText(l10n, s.actionError!),
            },
          };
          if (text != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(text)));
          }
        },
        builder: (context, s) => switch (s.load) {
          BillingLoad.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          BillingLoad.failure => AppEmptyState(
            message: s.error == null
                ? l10n.planLoadFailed
                : classesErrorText(l10n, s.error!),
            action: AppButton(label: l10n.classesRetry, onPressed: cubit.load),
          ),
          BillingLoad.ready => RefreshIndicator(
            onRefresh: cubit.refresh,
            child: _Body(state: s, openUrl: openUrl),
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.openUrl});
  final PlanState state;
  final Future<bool> Function(Uri) openUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<PlanCubit>();
    final u = state.usage!;
    const gap = SizedBox(height: AppSpacing.lg);
    final price = cubit.storePrice;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.isPro ? l10n.planNamePro : l10n.planNameFree,
                  style: text.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_statusText(l10n, u.status)),
                if (u.daysLeft != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.planDaysLeft(u.daysLeft!), style: text.titleMedium),
                ],
                if (u.endDate != null) Text(l10n.planEndsOn(u.endDate!)),
              ],
            ),
          ),
        ),
        gap,
        Text(l10n.planUsageTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _UsageRow(
          label: l10n.planUsageClasses,
          used: u.activeClasses,
          limit: u.maxActiveClasses,
        ),
        _UsageRow(
          label: l10n.planUsageStudents,
          used: u.activeStudents,
          limit: u.maxActiveStudents,
        ),
        if (u.hasReadOnly) ...[
          const SizedBox(height: AppSpacing.sm),
          AppBanner(
            tone: AppStatusTone.warning,
            description: l10n.planReadOnlyNote(
              u.readOnlyClasses,
              u.readOnlyStudents,
            ),
            fullWidth: true,
          ),
        ],
        gap,
        Text(l10n.planFeaturesTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final key in knownPlanFeatures)
          if (u.features.containsKey(key))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                u.features[key]! ? Icons.check_circle : Icons.lock_outline,
              ),
              title: Text(_featureLabel(l10n, key)),
              trailing: Text(
                u.features[key]! ? l10n.planFeatureOn : l10n.planFeatureLocked,
              ),
            ),
        gap,
        if (u.trialAvailable)
          AppButton(
            label: l10n.planTrialButton,
            width: double.infinity,
            onPressed: state.busy ? null : cubit.startTrial,
          )
        else if (!u.isPro)
          Text(l10n.planTrialUsed, style: text.bodyMedium),
        // Pro trả phí còn hạn thì không cần mua; đang dùng thử vẫn mua được.
        if (u.status != SubscriptionStatus.active) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: price == null
                ? l10n.planBuyButton
                : l10n.planBuyButtonPrice(price),
            variant: u.trialAvailable
                ? AppButtonVariant.outlinePrimary
                : AppButtonVariant.primary,
            width: double.infinity,
            onPressed: state.busy ? null : cubit.purchase,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l10n.planWebButton,
            variant: AppButtonVariant.outlinePrimary,
            width: double.infinity,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (!await openUrl(proWebUri)) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.planWebFailed)),
                );
              }
            },
          ),
        ],
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.used, this.limit});
  final String label;
  final int used;

  /// `null` = không giới hạn.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                limit == null
                    ? l10n.planUsageUnlimited(used)
                    : l10n.planUsageOfLimit(used, limit!),
              ),
            ],
          ),
          if (limit != null && limit! > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: (used / limit!).clamp(0, 1)),
          ],
        ],
      ),
    );
  }
}

String _statusText(MiniAppLocalizations l10n, SubscriptionStatus s) =>
    switch (s) {
      SubscriptionStatus.trialing => l10n.planStatusTrialing,
      SubscriptionStatus.active => l10n.planStatusActive,
      SubscriptionStatus.expired => l10n.planStatusExpired,
      SubscriptionStatus.free => l10n.planStatusFree,
    };

String _featureLabel(MiniAppLocalizations l10n, String key) => switch (key) {
  'compliance.form02' => l10n.planFeatureForm02,
  'compliance.form03' => l10n.planFeatureForm03,
  'revenue.export' => l10n.planFeatureRevenueExport,
  _ => l10n.planFeatureReportsExport,
};
