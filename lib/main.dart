import 'package:app_core/di.dart';
import 'package:app_framework/starter.dart';
import 'package:flutter/material.dart';
import 'package:mmkv/mmkv.dart';

import 'example_app_definitions.dart';

void main() {
  WidgetsBinding _ = WidgetsFlutterBinding.ensureInitialized();
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
