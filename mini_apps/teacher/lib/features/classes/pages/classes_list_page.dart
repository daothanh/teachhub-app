import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../classes_routes.dart';
import '../cubit/classes_list_cubit.dart';
import '../data/class_models.dart';
import '../data/classes_repository.dart';
import '../widgets/classes_error_text.dart';

/// T06: danh sách lớp. Mặc định lớp đang dạy; lớp lưu trữ ở tab riêng (US-1.1 AC3).
class ClassesListPage extends StatelessWidget {
  const ClassesListPage({super.key, this.repository});
  final ClassesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ClassesListCubit(repository ?? classesRepository())..load(),
    child: const _ClassesListView(),
  );
}

class _ClassesListView extends StatelessWidget {
  const _ClassesListView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ClassesListCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.classesTitle)),
      body: Column(
        children: [
          BlocBuilder<ClassesListCubit, ClassesListState>(
            buildWhen: (a, b) => a.archived != b.archived,
            builder: (context, s) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppChoiceChip(
                    label: l10n.classesTabActive,
                    selected: !s.archived,
                    onTap: () => cubit.load(archived: false),
                  ),
                  AppChoiceChip(
                    label: l10n.classesTabArchived,
                    selected: s.archived,
                    onTap: () => cubit.load(archived: true),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ClassesListCubit, ClassesListState>(
              builder: (context, s) => switch (s.load) {
                ClassesLoad.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                ClassesLoad.failure => AppEmptyState(
                  message: classesErrorText(l10n, s.error!),
                  action: AppButton(
                    label: l10n.classesRetry,
                    onPressed: cubit.load,
                  ),
                ),
                ClassesLoad.ready when s.items.isEmpty => AppEmptyState(
                  message: s.archived
                      ? l10n.classesEmptyArchived
                      : l10n.classesEmpty,
                  subMessage: s.archived ? null : l10n.classesEmptyHint,
                ),
                ClassesLoad.ready => _ClassList(state: s),
              },
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.lg),
            child: AppButton(
              label: l10n.classesCreate,
              width: double.infinity,
              onPressed: () async {
                final created = await context.push<TeachClass>(
                  ClassesRoutes.create,
                );
                if (created != null) cubit.refresh();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassList extends StatelessWidget {
  const _ClassList({required this.state});
  final ClassesListState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<ClassesListCubit>();
    final more = state.hasMore ? 1 : 0;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: state.items.length + more,
      itemBuilder: (context, i) {
        if (i == state.items.length) {
          if (state.loadMoreFailed) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: l10n.classesRetry,
                variant: AppButtonVariant.outlinePrimary,
                onPressed: cubit.retryLoadMore,
              ),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => cubit.loadMore());
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final c = state.items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard.outlined(
            onTap: () async {
              await context.push(ClassesRoutes.detail(c.id));
              cubit.refresh();
            },
            title: c.name,
            subtitle: l10n.classesItemMeta(c.subject, c.grade),
            trailing: Text(l10n.classesStudentCount(c.enrolledCount)),
          ),
        );
      },
    );
  }
}
