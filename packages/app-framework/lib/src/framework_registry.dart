import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:flutter/material.dart';
import 'package:sync_biz/sync_biz.dart';
import 'package:theme_biz/theme_biz.dart';

import 'ui/pages/launcher_page.dart';
import 'ui/scaffold/adaptive_scaffold.dart';
import 'ui/screens/settings_screen.dart';

part 'framework_registry.g.dart';

class FrameworkRegistry {
  final Ref _ref;

  FrameworkRegistry({required Ref ref}) : _ref = ref;

  List<RouteBase> get routes => [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdaptiveScaffold(navigationShell: navigationShell),
      branches: [
        // Tab 1: 仪表盘 (聚合信息)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => Container(),
            ),
          ],
        ),

        // Tab 2: 应用库 (所有功能入口)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.launcher,
              builder: (context, state) => LauncherPage(),
            ),
          ],
        ),

        // Tab 3: 我的/设置
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings, // '/settings'
              builder: (context, state) => SettingsScreen(),
              routes: [
                _ref.read(syncSettingsRouteProvider),
                _ref.read(themeSettingsRouteProvider),
              ],
            ),
          ],
        ),
      ],
    ),
    ..._ref.read(authRoutesProvider),
  ];

  List<StartupAction> get startups => [
    _ref.read(checkTokenActionProvider),
    _ref.read(checkRealtimeSyncProvider),
  ];
}

@Riverpod(keepAlive: true)
FrameworkRegistry frameworkRegistry(Ref ref) {
  return FrameworkRegistry(ref: ref);
}
