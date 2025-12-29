import 'dart:async';

import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'framework_database.dart';
import 'launcher/app_usage_dao.dart';

part 'dao_providers.g.dart';

@riverpod
Future<FrameworkDatabase> frameworkDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(
      DatabaseId('framework', (e) => FrameworkDatabase(e)),
    ).future,
  );
}

@riverpod
Future<AppUsageDao> appUsageDao(Ref ref) async {
  return AppUsageDao(await ref.watch(frameworkDatabaseProvider.future));
}
