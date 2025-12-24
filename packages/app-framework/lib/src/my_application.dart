import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import 'framework_providers.dart';

class MyApplication extends ConsumerWidget {
  const MyApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(startupProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Flutter Framework Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 连接 GoRouter
      routerConfig: ref.read(appRouterProvider),
    );
  }
}
