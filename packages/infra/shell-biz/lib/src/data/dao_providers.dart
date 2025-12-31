import 'dart:async';

import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import 'shell_database.dart';
import 'launcher/app_usage_dao.dart';

part 'dao_providers.g.dart';

@riverpod
Future<ShellDatabase> shellDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(
      DatabaseId('shell', (e) => ShellDatabase(e)),
    ).future,
  );
}

@riverpod
Future<AppUsageDao> appUsageDao(Ref ref) async {
  return AppUsageDao(await ref.watch(shellDatabaseProvider.future));
}
