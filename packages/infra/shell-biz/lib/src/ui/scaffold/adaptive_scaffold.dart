import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import 'desktop_scaffold.dart';
import 'mobile_scaffold.dart';

class AdaptiveScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 断点设置：小于 600dp 视为手机
        if (constraints.maxWidth < 600) {
          return MobileScaffold(navigationShell: navigationShell);
        } else {
          return DesktopScaffold(navigationShell: navigationShell);
        }
      },
    );
  }
}
