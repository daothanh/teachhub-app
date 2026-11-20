import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';
import '../cubit/student_picker_cubit.dart';
import '../data/classes_repository.dart';
import '../widgets/classes_error_text.dart';

/// Thêm học viên có sẵn vào lớp (S2-FL-11): tìm không dấu, chọn hồ sơ, ghi danh.
/// Không tạo hồ sơ mới ở đây. Đóng với `true` khi ghi danh xong.
class StudentPickerPage extends StatelessWidget {
  const StudentPickerPage({super.key, required this.classId, this.repository});
  final String classId;
  final ClassesRepository? repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentPickerCubit(repository ?? classesRepository(), classId),
    child: const _PickerView(),
  );
}

class _PickerView extends StatelessWidget {
  const _PickerView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    final cubit = context.read<StudentPickerCubit>();
    return BlocConsumer<StudentPickerCubit, StudentPickerState>(
      listenWhen: (a, b) => a.done != b.done && b.done != null,
      listener: (context, s) {
        final d = s.done!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              d.result.alreadyEnrolled
                  ? l10n.classesAlreadyEnrolled(d.student.fullName)
                  : l10n.classesEnrolled(d.student.fullName),
            ),
          ),
        );
        context.pop(true);
      },
      builder: (context, s) => Scaffold(
        appBar: AppBar(title: Text(l10n.classesPickerTitle)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppSearchField(
                hint: l10n.classesPickerSearchHint,
                onChanged: cubit.search,
              ),
            ),
            if (s.error != null)
              AppBanner(
                tone: AppStatusTone.error,
                description: classesErrorText(l10n, s.error!, enroll: true),
                fullWidth: true,
              ),
            Expanded(child: _Results(state: s)),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});
  final StudentPickerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.miniAppL10n;
    if (state.queryTooShort) {
      return Center(child: Text(l10n.classesPickerTooShort));
    }
    if (state.searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.results.isEmpty && state.error == null) {
      return AppEmptyState(
        message: l10n.classesPickerNone,
        subMessage: l10n.classesPickerNoneHint,
      );
    }
    final cubit = context.read<StudentPickerCubit>();
    return ListView(
      children: [
        for (final s in state.results)
          AppListTile(
            title: s.fullName,
            subtitle: [
              s.school,
              s.schoolClass,
            ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
            isLoading: state.enrollingId == s.id,
            enabled: state.enrollingId == null,
            onTap: () => cubit.enroll(s),
          ),
      ],
    );
  }
}
