import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import 'service/auto_sync_service.dart';
import 'service/sync_service.dart';

part 'providers.g.dart';

@riverpod
Future<bool> autoSyncEnabled(Ref ref) {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<SyncService> syncService(Ref ref) {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<AutoSyncService> autoSyncService(Ref ref) {
  throw NotOverrideError();
}
