import 'package:app_core/di.dart';
import 'package:auth_api/auth_api.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:sync_api/sync_api.dart';

import '../domain/sync_cursor.dart';
import '../need_override_providers.dart';
import '../state/sync_states.dart';
import 'impl/realtime_service_impl.dart';
import 'impl/sync_service_impl.dart';
import 'realtime_service.dart';
import 'sync_all_service.dart';
import 'sync_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SyncServiceImpl> syncServiceImpl(Ref ref) async {
  final delegates = await ref.watch(syncDelegatesProvider.future);
  final delegateMap = {
    for (var delegate in delegates) delegate.resourceId: delegate,
  };

  return SyncServiceImpl(
    delegateMap: delegateMap,
    syncingGetter: (resourceId) {
      return ref.read(resourceSyncingProvider(resourceId));
    },
    syncingSetter: (resourceId, syncing) {
      final notifier = ref.read(syncingProvider.notifier);
      notifier.setSyncing(resourceId, syncing);
    },
    syncChecker: () async {
      final userIdentity = await ref.read(currentUserIdentityProvider.future);
      if (userIdentity == null) {
        return false;
      }
      final settings = await ref.read(syncSettingsProvider.future);
      return settings.enable;
    },
    cursorLoader: (resourceId) async {
      final cursor = await ref.read(syncCursorProvider(resourceId).future);
      return cursor.cursor;
    },
    cursorUpdater: (resourceId, cursor) async {
      final notifier = ref.read(syncCursorProvider(resourceId).notifier);
      return notifier.save(SyncCursor(cursor: cursor, lastSyncedAt: cursor));
    },
  );
}

@Riverpod(keepAlive: true)
Future<SyncAllService> syncAllService(Ref ref) async {
  return await ref.watch(syncServiceImplProvider.future);
}

@Riverpod(keepAlive: true)
Future<SyncService> syncService(Ref ref) async {
  return await ref.watch(syncServiceImplProvider.future);
}

@Riverpod(keepAlive: true)
Future<RealtimeService?> realtimeService(Ref ref) async {
  final userIdentity = await ref.watch(currentUserIdentityProvider.future);
  if (userIdentity == null) {
    return null;
  }
  final authenciatedToken = await ref.watch(
    authenciatedAccessTokenProvider.future,
  );
  if (authenciatedToken == null) {
    return null;
  }
  final availability = ref.watch(connectionAvailabiltyProvider);
  if (availability != ConnectionAvailability.active) {
    return null;
  }

  final service = RealtimeServiceImpl(
    server: userIdentity.server,
    token: authenciatedToken,
    onAuthExpired: () async {
      final action = ref.read(refreshAccessTokenProvider);
      await action();
    },
    triggerSyncAction: ref.read(syncActionProvider),
  );

  // 4. 生命周期管理
  // 初始化时启动
  service.start();

  // 销毁时停止 (包括 Token 变化导致的重建前夕)
  ref.onDispose(() {
    service.stop();
  });
  return service;
}
