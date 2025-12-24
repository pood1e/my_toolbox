import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../need_override_providers.dart';
import '../ui/scaffold/adaptive_scaffold.dart';
import '../ui/screens/settings_screen.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      // 1. 带有底部导航栏的 Shell (只有3个Tab)
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
                builder: (context, state) => Container(),
              ),
            ],
          ),

          // Tab 3: 我的/设置
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings, // '/settings'
                builder: (context, state) => SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      ...ref.read(routesProvider),
    ],
  );
}
