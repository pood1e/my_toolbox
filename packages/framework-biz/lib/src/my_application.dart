import 'dart:ui';

import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:theme_biz/theme_biz.dart';

import 'framework_providers.dart';

class MyApplication extends ConsumerWidget {
  const MyApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(startupProvider);

    return ThemeSupplier(
      builder: (lightTheme, darkTheme, themeMode) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        routerConfig: ref.read(appRouterProvider),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
      ),
    );
  }
}
