import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../cubit/tuition_cubit.dart';
import 'invoice_format.dart';

/// Card học phí ở P02: số hóa đơn chưa thanh toán và tổng, bấm mở P03 (US-7.3).
/// Đặt dưới `BlocProvider<TuitionCubit>`; chưa tải xong hoặc lỗi thì ẩn.
class TuitionCard extends StatelessWidget {
  const TuitionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    return BlocBuilder<TuitionCubit, TuitionState>(
      builder: (context, s) {
        if (!s.loaded) return const SizedBox.shrink();
        final text = s.count == 0
            ? l10n.invoiceTuitionNone
            : l10n.invoiceTuitionUnpaid(s.count, formatVnd(context, s.total));
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(TeachHubRoutes.parentInvoices),
            child: Semantics(
              button: true,
              container: true,
              label: '${l10n.invoiceTuitionTitle}. $text',
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.invoiceTuitionTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(text, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
