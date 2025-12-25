import 'package:app_core/logger.dart';
import 'package:auth_api/auth_api.dart';
import 'package:data_api/data_api.dart';

import '../../domain/scope_type.dart';
import '../data_migration_service.dart';
import '../data_scope_service.dart';

class DataMigrationServiceImpl implements DataMigrationService {
  final DataScopeService _service;
  final List<Migratable<dynamic>> _migrations;

  DataMigrationServiceImpl({
    required DataScopeService scopeService,
    required List<Migratable<dynamic>> migrations,
  }) : _service = scopeService,
       _migrations = migrations;

  @override
  Future<void> migrateFromGuest(UserIdentity userId) async {
    final guestScope = await _service.get(GuestScope().id);
    final userScope = await _service.get(UserScope(identity: userId).id);

    await Future.wait(
      _migrations.map((migratable) async {
        try {
          final guestStore = guestScope.get(migratable.definition);
          final userStore = userScope.get(migratable.definition);
          await migratable.migrate(guestStore, userStore);
        } catch (e) {
          logger.e('Error migrating ${migratable.definition.key}', error: e);
        }
      }),
    );

    await guestScope.delete();
  }

  @override
  Future<bool> hasAnyNeedMigrate() async {
    final guestScope = await _service.get(GuestScope().id);
    final filtered = await Future.wait(
      _migrations.map((migratable) async {
        try {
          final guestStore = guestScope.get(migratable.definition);
          return await migratable.hasData(guestStore);
        } catch (e) {
          logger.e(
            'Error when check migration ${migratable.definition.key}',
            error: e,
          );
          return false;
        }
      }),
    );
    return filtered.any((t) => t);
  }
}
