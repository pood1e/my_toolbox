import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:mmkv/mmkv.dart';

import 'feature_registry.dart';
import 'framework_overrides.dart';
import 'my_application.dart';

Future<void> startApp({FeatureRegistry? featureRegistry}) async {
  WidgetsBinding _ = WidgetsFlutterBinding.ensureInitialized();
  MMKV.initialize(logLevel: MMKVLogLevel.Error);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final overrides = frameworkOverrides;
  if (featureRegistry != null) {
    overrides.add(featureRegistryProvider.overrideWithValue(featureRegistry));
  }
  runApp(ProviderScope(overrides: overrides, child: MyApplication()));
}
