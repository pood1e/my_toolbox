import 'package:auth_biz/auth_biz.dart';
import 'package:core/di.dart';
import 'package:sync_api/sync_api.dart';

import '../domain/sync_cursor.dart';
import '../need_override_providers.dart';
import '../state/sync_states.dart';
import 'impl/realtime_service_impl.dart';
import 'impl/sync_service_impl.dart';
import 'realtime_service.dart';
import 'sync_all_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<Map<String, SyncDelegate<dynamic>>> syncDelegateMap(Ref ref) async {
  final delegates = await ref.watch(syncDelegatesProvider.future);
  return {for (var delegate in delegates) delegate.resourceId: delegate};
}

@riverpod
bool resourceSyncing(Ref ref, String resourceId) {
  final syncingMap = ref.read(syncingProvider);
  return syncingMap[resourceId] ?? false;
}

@riverpod
bool anySyncing(Ref ref) {
  final syncingMap = ref.watch(syncingProvider);
  return syncingMap.values.any((syncing) => syncing);
}

@Riverpod(keepAlive: true)
Future<SyncServiceImpl> syncServiceImpl(Ref ref) async {
  final delegateMap = await ref.read(syncDelegateMapProvider.future);

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
Future<RealtimeService?> realtimeService(Ref ref) async {
  // 1. [核心] 监听依赖变化
  // 只要 server 或 auth 发生变化 (包括 Token 刷新)，
  // Riverpod 会自动 Dispose 当前的 Service 实例，并重新执行这个函数创建新的。
  final server = await ref.watch(remoteServerProvider.future);
  final token = await ref.watch(accessTokenProvider.future);
  final availability = ref.watch(connectionAvailabiltyProvider);

  if (server == null ||
      token == null ||
      availability != ConnectionAvailability.active) {
    return null;
  }

  final syncService = await ref.watch(syncServiceProvider.future);

  // 2. 创建 Service 实例
  final service = RealtimeServiceImpl(
    server: server,
    token: token,
    syncService: syncService,
    onAuthExpired: () async {
      // 3. 处理 401
      // 当 Service 内部报 401 时，我们只需要调用 Auth 模块的刷新逻辑。
      // 刷新成功后，authStateProvider 会更新 -> 触发上面的 ref.watch -> 自动重建 Service
      final tokenService = await ref.read(tokenServiceProvider.future);
      await tokenService.refresh();
    },
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
