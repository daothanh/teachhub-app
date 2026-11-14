import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../../l10n/l10n.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String category; // 'system', 'transaction', 'miniapp'
  final String? iconPath;
  final IconData? icon;
  final Color? iconBgColor;
  final String? route;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.category,
    this.iconPath,
    this.icon,
    this.iconBgColor,
    this.route,
    this.isRead = false,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedFilterIndex = 0;

  late final List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Chào mừng bạn đến với Tasco SuperApp',
        body:
            'Khám phá hệ sinh thái dịch vụ đa dạng và tiện ích từ Tasco ngay hôm nay!',
        time: DateTime.now().subtract(const Duration(minutes: 15)),
        category: 'system',
        iconPath: AppIcons.bell,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Trải nghiệm VueJS Mini App mới',
        body:
            'Mini App VueJS đã sẵn sàng với kiến trúc Web Bridge độc lập an toàn.',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'miniapp',
        iconPath: AppIcons.network,
        route: '/vue_mini_app',
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Cập nhật bảo mật tài khoản',
        body:
            'Tính năng đăng nhập sinh trắc học đã được nâng cấp với độ tin cậy cao.',
        time: DateTime.now().subtract(const Duration(days: 1)),
        category: 'system',
        iconPath: AppIcons.security,
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Giao dịch đơn dịch vụ thành công',
        body:
            'Đơn dịch vụ #TSC-88392 đã được xử lý và ghi nhận vào hồ sơ của bạn.',
        time: DateTime.now().subtract(const Duration(days: 2)),
        category: 'transaction',
        iconPath: AppIcons.order,
        isRead: true,
      ),
    ];
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 0) return _notifications;
    final cat = switch (_selectedFilterIndex) {
      1 => 'system',
      2 => 'transaction',
      3 => 'miniapp',
      _ => '',
    };
    return _notifications.where((n) => n.category == cat).toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filters = [
      l10n.notificationFilterAll,
      l10n.notificationFilterSystem,
      l10n.notificationFilterTransaction,
      l10n.notificationFilterMiniApps,
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppMainAppBar(
        title: l10n.notificationTitle,
        showLeading: Navigator.of(context).canPop(),
        onLeadingTap: () => Navigator.of(context).pop(),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                l10n.notificationMarkAllAsRead,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: AppTag(
                      label: filters[index],
                      selected: isSelected,
                      onTap: () => setState(() => _selectedFilterIndex = index),
                    ),
                  );
                }),
              ),
            ),
          ),
          const AppDivider(),

          // Notification List / Empty State
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: AppEmptyState(
                      message: l10n.notificationEmptyTitle,
                      subMessage: l10n.notificationEmptyMessage,
                      icon: AppSvgIcon(
                        AppIcons.notification,
                        size: 48.sp,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    itemCount: _filteredNotifications.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final item = _filteredNotifications[index];
                      return _NotificationCard(
                        item: item,
                        scheme: scheme,
                        textTheme: textTheme,
                        onTap: () {
                          setState(() => item.isRead = true);
                          if (item.route != null) {
                            context.go(item.route!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.scheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bgColor = item.isRead
        ? scheme.surface
        : scheme.primary.withValues(alpha: 0.05);

    final border = item.isRead
        ? Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5))
        : Border.all(color: scheme.primary.withValues(alpha: 0.25));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: border,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: item.isRead
                    ? scheme.surfaceContainerHighest
                    : scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: item.iconPath != null
                    ? AppSvgIcon(
                        item.iconPath!,
                        size: 20.sp,
                        color: item.isRead
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                      )
                    : Icon(
                        item.icon ?? Icons.notifications_outlined,
                        size: 20.sp,
                        color: item.isRead
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                      ),
              ),
            ),
            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        SizedBox(width: 6.w),
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatTime(item.time, l10n),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}
