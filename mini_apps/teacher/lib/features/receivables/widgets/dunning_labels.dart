import '../../../l10n/l10n.dart';
import '../../billing/data/billing_models.dart' show formatIsoDateTime;
import '../data/receivable_models.dart';

String agingBucketLabel(MiniAppLocalizations l10n, AgingBucket b) =>
    switch (b) {
      AgingBucket.upTo30 => l10n.receivablesBucket030,
      AgingBucket.from31To60 => l10n.receivablesBucket3160,
      AgingBucket.over60 => l10n.receivablesBucketOver60,
    };

/// Mốc theo ngày so với hạn: "Trước hạn 1 ngày", "Đúng hạn", "Sau hạn 3 ngày".
String dunningOffsetLabel(MiniAppLocalizations l10n, int days) => days < 0
    ? l10n.dunningOffsetBefore(-days)
    : days == 0
    ? l10n.dunningOffsetOn
    : l10n.dunningOffsetAfter(days);

/// "Đã gửi 09/01/2027 09:00", "Chờ gửi …" hoặc "Đã hủy".
String dunningStepText(MiniAppLocalizations l10n, DunningStep s) =>
    switch (s.status) {
      DunningStepStatus.sent => l10n.dunningStepSent(
        formatIsoDateTime(s.sentAt ?? s.scheduledFor),
      ),
      DunningStepStatus.pending => l10n.dunningStepPending(
        formatIsoDateTime(s.scheduledFor),
      ),
      DunningStepStatus.cancelled => l10n.dunningStepCancelled,
    };

String dunningReasonText(MiniAppLocalizations l10n, DunningDisabledReason r) =>
    switch (r) {
      DunningDisabledReason.tenantDisabled => l10n.dunningReasonTenant,
      DunningDisabledReason.studentDisabled => l10n.dunningReasonStudent,
      DunningDisabledReason.paid => l10n.dunningReasonPaid,
      DunningDisabledReason.voided => l10n.dunningReasonVoid,
    };
