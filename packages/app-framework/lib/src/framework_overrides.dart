import 'package:app_core/di.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:data_biz/data_biz.dart';
import 'package:framework_api/framework_api.dart';
import 'package:sync_biz/sync_biz.dart';

import 'data/sync/sync_delegate_providers.dart';
import 'logic/login_interceptors.dart';

List<Override> frameworkOverrides = [
  // auth-biz
  beforeLoginsProvider.overrideWith((ref) async {
    return [
      ref.read(migrateBeforeLoginProvider),
      ref.read(closeUserScopeBeforeLoginProvider),
    ];
  }),
  afterLoginsProvider.overrideWithValue(AsyncValue.data([])),
  beforeLogoutsProvider.overrideWith((ref) async {
    return [ref.read(closeUserScopeBeforeLogoutProvider)];
  }),
  afterLogoutsProvider.overrideWithValue(AsyncValue.data([])),
  // auth-api
  authenticatedDioProvider.overrideWith(AuthApiOverride.authenticatedDio),
  currentUserIdentityProvider.overrideWith(AuthApiOverride.currentUserIdentity),

  // data-biz
  migrationsProvider.overrideWithValue(AsyncValue.data([])),
  // data-api
  kvStorageDefinitionProvider.overrideWith(DataApiOverride.kvStorageDefinition),
  dbStorageDefinitionProvider.overrideWith(DataApiOverride.dbStorageDefinition),
  globalKvStoreProvider.overrideWith(DataApiOverride.globalKvStore),
  globalDbStoreProvider.overrideWith(DataApiOverride.globalDbStore),
  userKvStoreProvider.overrideWith(DataApiOverride.userKvStore),
  userDbStoreProvider.overrideWith(DataApiOverride.userDbStore),

  // sync-biz
  syncDelegatesProvider.overrideWith((ref) async {
    return [await ref.read(launcherSyncDelegateProvider.future)];
  }),
  // sync-api
  syncActionProvider.overrideWith(SyncApiOverride.syncAction),
  autoSyncProvider.overrideWith(SyncApiOverride.autoSync),
  syncStandardApiProvider.overrideWith(SyncApiOverride.syncStandardApi),
];
