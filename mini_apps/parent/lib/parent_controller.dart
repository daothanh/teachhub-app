import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_module/tasco_module.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'features/family/cubit/family_cubit.dart';
import 'features/family/data/family_repository.dart';
import 'features/home/pages/parent_home_page.dart';
import 'features/invoice/cubit/invoice_detail_cubit.dart';
import 'features/invoice/cubit/invoice_list_cubit.dart';
import 'features/invoice/cubit/receipt_claim_cubit.dart';
import 'features/invoice/data/invoice_repository.dart';
import 'features/invoice/data/qr_image_saver.dart';
import 'features/invoice/data/receipt_picker.dart';
import 'features/invoice/data/receipt_repository.dart';
import 'features/invoice/pages/invoice_detail_page.dart';
import 'features/invoice/pages/invoice_list_page.dart';
import 'l10n/l10n.dart';
import 'notification_permission_gate.dart';

/// Mini-app không gian Phụ huynh (spec §3.7), route gốc [TeachHubRoutes.parent].
///
/// Gọi API qua `Dio` dùng chung của host (`TeachHubDiKey.api`) nên không tự
/// dựng client, không giữ token.
class ParentController {
  ParentController._();
  static final instance = ParentController._();

  String get moduleId => 'parent';
  String get routePrefix => TeachHubRoutes.parent;

  /// Host gắn P05 (nhận lời mời) hiện khi phụ huynh chưa có con nào.
  NoInviteBuilder? noInviteBuilder;

  /// Host gắn quyền thông báo (FCM); `null` thì không hiện banner bật thông báo.
  NotificationPermissionGate? notifications;

  /// Test thay bằng bản giả; mặc định gọi `Dio` của host.
  @visibleForTesting
  FamilyRepository? familyRepository;

  @visibleForTesting
  InvoiceRepository? invoiceRepository;

  @visibleForTesting
  QrImageSaver? qrImageSaver;

  @visibleForTesting
  ReceiptRepository? receiptRepository;

  @visibleForTesting
  ReceiptPicker? receiptPicker;

  InvoiceRepository _invoices() =>
      invoiceRepository ??
      DioInvoiceRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

  List<LocalizationsDelegate> get localizationsDelegates =>
      MiniAppLocalizations.localizationsDelegates;

  List<RouteBase> routes() => [
    GoRoute(
      path: routePrefix,
      name: '$moduleId.home',
      builder: (context, state) => BlocProvider(
        create: (_) => FamilyCubit(
          familyRepository ??
              DioFamilyRepository(
                GetIt.I<Dio>(instanceName: TeachHubDiKey.api),
              ),
          notifications: notifications,
        )..load(),
        child: ParentHomePage(
          noInviteBuilder: noInviteBuilder,
          invoiceRepository: _invoices,
        ),
      ),
      routes: [
        // P03: danh sách và chi tiết hóa đơn (US-7.3).
        GoRoute(
          path: 'invoices',
          name: '$moduleId.invoices',
          builder: (context, state) => BlocProvider(
            create: (_) => InvoiceListCubit(_invoices())..load(),
            child: const InvoiceListPage(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              name: '$moduleId.invoice',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => InvoiceDetailCubit(
                      _invoices(),
                      qrImageSaver ?? const GalQrImageSaver(),
                      state.pathParameters['id']!,
                    )..load(),
                  ),
                  // Giữ qua các lần mở sheet: URL và khóa Idempotency còn dùng lại khi thử lại.
                  BlocProvider(
                    create: (_) => ReceiptClaimCubit(
                      receiptRepository ??
                          DioReceiptRepository(
                            GetIt.I<Dio>(instanceName: TeachHubDiKey.api),
                            GetIt.I<Dio>(
                              instanceName: TeachHubDiKey.objectStorage,
                            ),
                          ),
                      receiptPicker ?? const ImagePickerReceiptPicker(),
                      state.pathParameters['id']!,
                    ),
                  ),
                ],
                child: const InvoiceDetailPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  ];

  ModuleSlot toModuleSlot() => ModuleSlot(
    moduleId: moduleId,
    routePrefix: routePrefix,
    notificationTypes: const {},
    init: () async {},
    routes: routes,
    onNotification: (type, data) async {},
    dispose: () async {},
  );
}
