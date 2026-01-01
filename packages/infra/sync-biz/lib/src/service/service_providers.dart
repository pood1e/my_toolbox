import 'package:app_core/di.dart';
import 'package:auth_api/auth_api.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:sync_api/sync_api.dart';

import '../domain/sync_exceptions.dart';
import '../need_override_providers.dart';
import '../state/sync_settings_state.dart';
import 'impl/realtime_service_impl.dart';
import 'impl/sync_service_impl.dart';
import 'realtime_service.dart';
import 'sync_all_service.dart';
import 'sync_service.dart';

part 'service_providers.g.dart';

@riverpod
Future<SyncServiceImpl> syncServiceImpl(Ref ref) async {
  final delegates = await ref.watch(syncDelegatesProvider.future);
  final delegateMap = {
    for (var delegate in delegates) delegate.resourceId: delegate,
  };

  return SyncServiceImpl(delegateMap: delegateMap);
}

@riverpod
Future<SyncAllService> syncAllService(Ref ref) async {
  final syncEnabled = await ref.watch(syncEnabledProvider.future);
  if (!syncEnabled) {
    throw SyncDisallowException();
  }
  return await ref.watch(syncServiceImplProvider.future);
}

@riverpod
Future<SyncService> syncService(Ref ref) async {
  final syncEnabled = await ref.watch(syncEnabledProvider.future);
  if (!syncEnabled) {
    throw SyncDisallowException();
  }
  return await ref.watch(syncServiceImplProvider.future);
}

@riverpod
Future<bool> anySyncing(Ref ref) async {
  final service = await ref.read(syncServiceProvider.future);
  return service.anySyncing;
}

@riverpod
Future<RealtimeService> realtimeService(Ref ref) async {
  final userIdentity = await ref.watch(currentUserIdentityProvider.future);
  if (userIdentity == null) {
    throw SyncDisallowException();
  }
  final realtimeEnabled = await ref.watch(realtimeSyncEnabledProvider.future);
  if (!realtimeEnabled) {
    throw SyncDisallowException();
  }
  final authenciatedToken = await ref.watch(
    authenciatedAccessTokenProvider.future,
  );
  if (authenciatedToken == null) {
    throw SyncUnavailableException();
  }
  final availability = ref.watch(connectionAvailabiltyProvider);
  if (availability != ConnectionAvailability.active) {
    throw SyncUnavailableException();
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
  service.start();
  ref.onDispose(() {
    service.stop();
  });
  return service;
}
