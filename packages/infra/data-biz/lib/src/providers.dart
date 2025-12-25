/// 提供给框架使用
library;

import 'package:app_core/di.dart';
import 'package:auth_api/auth_api.dart';

import 'domain/scope_type.dart';
import 'need_override_providers.dart';
import 'service/impl/data_migration_service_impl.dart';
import 'service/service_providers.dart';

part 'providers.g.dart';

@riverpod
Future<void> Function() migrateFromGuestAction(Ref ref, UserIdentity userId) {
  return () async {
    final service = await ref.read(dataScopeServiceProvider.future);
    final migrations = await ref.watch(migrationsProvider.future);
    final migrationService = DataMigrationServiceImpl(
      migrations: migrations,
      scopeService: service,
    );
    await migrationService.migrateFromGuest(userId);
  };
}

@riverpod
Future<bool> Function() checkAnyNeedMigrate(Ref ref) {
  return () async {
    final service = await ref.read(dataScopeServiceProvider.future);
    final migrations = await ref.watch(migrationsProvider.future);
    final migrationService = DataMigrationServiceImpl(
      migrations: migrations,
      scopeService: service,
    );
    return await migrationService.hasAnyNeedMigrate();
  };
}

@riverpod
Future<void> Function() closeUserAction(Ref ref) {
  return () async {
    final manager = await ref.read(dataScopeServiceProvider.future);
    final userId = await ref.read(currentUserIdentityProvider.future);
    final scopeId = userId == null ? GuestScope() : UserScope(identity: userId);
    await manager.close(scopeId.id);
  };
}

@riverpod
Future<void> Function() clearGuestAction(Ref ref) {
  return () async {
    final manager = await ref.read(dataScopeServiceProvider.future);
    await manager.delete(GuestScope().id);
  };
}

@riverpod
Future<void> Function() clearUserAction(Ref ref) {
  return () async {
    final manager = await ref.read(dataScopeServiceProvider.future);
    final userId = await ref.read(currentUserIdentityProvider.future);
    final scopeId = userId == null ? GuestScope() : UserScope(identity: userId);
    await manager.delete(scopeId.id);
  };
}

@riverpod
Future<void> Function() clearGlobalAction(Ref ref) {
  return () async {
    final manager = await ref.read(dataScopeServiceProvider.future);
    await manager.delete(GlobalScope().id);
  };
}
