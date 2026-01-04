import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:framework_api/framework_api.dart';
import 'package:mmkv/mmkv.dart';

import 'framework_overrides.dart';
import 'my_application.dart';

Future<void> startApp({
  FeatureRegistry? featureRegistry,
  List<Override> featureOverrides = const [],
}) async {
  WidgetsBinding _ = WidgetsFlutterBinding.ensureInitialized();
  MMKV.initialize(logLevel: MMKVLogLevel.Error);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final overrides = [...frameworkOverrides, ...featureOverrides];
  if (featureRegistry != null) {
    overrides.add(featureRegistryProvider.overrideWithValue(featureRegistry));
  }
  runApp(ProviderScope(overrides: overrides, child: MyApplication()));
}
