import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';

import '../../features/home/home_dashboard_page.dart';
import '../../features/notification/pages/notification_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../l10n/l10n.dart';

class MainShellPage extends StatefulWidget {
  final int initialTab;

  const MainShellPage({super.key, this.initialTab = 0});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late final PreloadPageController _pageController;
  late final AppShellController _shellController;
  late int _currentIndex;

  static final _pages = [
    const HomeDashboardPage(),
    const Scaffold(body: Center(child: Text('Explore'))),
    const NotificationPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pageController = PreloadPageController(initialPage: widget.initialTab);
    _shellController = AppShellController()..selectTab(widget.initialTab);
  }

  @override
  void didUpdateWidget(MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != _currentIndex) {
      _onTabChanged(widget.initialTab);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _shellController.selectTab(index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      AppShellTab(
        label: l10n.tabHome,
        iconPath: AppIcons.home,
        activeIconPath: AppIcons.homeActive,
      ),
      AppShellTab(
        label: l10n.tabExplore,
        iconPath: AppIcons.document,
        activeIconPath: AppIcons.document,
      ),
      AppShellTab(
        label: l10n.tabNotification,
        iconPath: AppIcons.notification,
        activeIconPath: AppIcons.notification,
      ),
      AppShellTab(
        label: l10n.tabProfile,
        iconPath: AppIcons.user,
        activeIconPath: AppIcons.userActive,
      ),
    ];

    return AppMainShell(
      tabs: tabs,
      body: PreloadPageView(
        controller: _pageController,
        preloadPagesCount: _pages.length,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) {
          setState(() => _currentIndex = i);
          _shellController.selectTab(i);
        },
        children: _pages,
      ),
      controller: _shellController,
      onTabChanged: _onTabChanged,
    );
  }
}
