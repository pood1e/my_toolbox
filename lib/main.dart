import 'package:core/di.dart';
import 'package:flutter/material.dart';
import 'package:framework_biz/starter.dart';
import 'package:mmkv/mmkv.dart';

import 'example_app_definitions.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  MMKV.initialize();

  final definition = OverrideDefinition();

  final overrides = [
    appDefinitionsProvider.overrideWithValue(kExampleApps),
    routesProvider.overrideWithValue(definition.routes),
    startupActionsProvider.overrideWithValue(definition.startupActions),
    syncDelegatesProvider.overrideWith(definition.getSyncDelegates),
  ];
  runApp(ProviderScope(overrides: overrides, child: MyApplication()));
}
