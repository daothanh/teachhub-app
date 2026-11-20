import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../../l10n/l10n.dart';
import '../cubit/invoice_list_cubit.dart';
import '../data/invoice_models.dart';
import '../widgets/invoice_format.dart';

/// P03: danh sách hóa đơn của các con (US-7.3).
class InvoiceListPage extends StatelessWidget {
  const InvoiceListPage({super.key});

  static const _filters = [
    InvoiceStatus.issued,
    InvoiceStatus.pendingConfirmation,
    InvoiceStatus.partiallyPaid,
    InvoiceStatus.paid,
    InvoiceStatus.voided,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<InvoiceListCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoiceListTitle)),
      body: BlocBuilder<InvoiceListCubit, InvoiceListState>(
        builder: (context, state) {
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.invoiceFilterAll),
                      selected: state.filter == null,
                      onSelected: (_) => cubit.load(),
                    ),
                    for (final f in _filters)
                      ChoiceChip(
                        label: Text(statusLabel(context, f)),
                        selected: state.filter == f,
                        onSelected: (_) => cubit.load(filter: f),
                      ),
                  ],
                ),
              ),
              Expanded(child: _Body(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final InvoiceListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<InvoiceListCubit>();
    return switch (state.status) {
      InvoiceListStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      InvoiceListStatus.failure => AppEmptyState(
        message: l10n.invoiceLoadFailed,
        action: AppButton(
          label: l10n.parentRetry,
          onPressed: () => cubit.load(keepFilter: true),
        ),
      ),
      InvoiceListStatus.ready when state.items.isEmpty => AppEmptyState(
        message: l10n.invoiceEmpty,
      ),
      InvoiceListStatus.ready => RefreshIndicator(
        onRefresh: () => cubit.load(keepFilter: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            for (final i in state.items) _Row(invoice: i),
            if (state.hasMore)
              Center(
                child: state.loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      )
                    : TextButton(
                        onPressed: cubit.loadMore,
                        child: Text(
                          state.moreFailed
                              ? l10n.parentRetry
                              : l10n.invoiceLoadMore,
                        ),
                      ),
              ),
          ],
        ),
      ),
    };
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.invoice});

  final InvoiceSummary invoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final theme = Theme.of(context);
    final voided = invoice.status == InvoiceStatus.voided;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () =>
            context.push('${TeachHubRoutes.parentInvoices}/${invoice.id}'),
        title: Text(
          l10n.invoiceRowSubtitle(
            invoice.studentName,
            formatMonth(context, invoice.periodMonth),
          ),
        ),
        subtitle: Text(
          '${statusLabel(context, invoice.status)} · '
          '${l10n.invoiceDue(formatDate(context, invoice.dueDate))}',
        ),
        trailing: Text(
          formatVnd(context, invoice.totalAmount),
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: voided ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
