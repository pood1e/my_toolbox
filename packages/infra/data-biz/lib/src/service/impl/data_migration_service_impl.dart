import 'package:auth_biz/auth_biz.dart';
import 'package:core/logger.dart';

import '../../domain/migrator.dart';
import '../../scope/data_scope.dart';
import '../data_migration_service.dart';
import '../data_scope_service.dart';

class DataMigrationServiceImpl implements DataMigrationService {
  final DataScopeService _scopeService;
  final List<FeatureDbMigrator> _dbMigrators;
  final List<FeatureKvMigrator> _kvMigrators;
  final MigrationDbFactory _dbFactory;

  DataMigrationServiceImpl({
    required DataScopeService manager,
    required List<FeatureDbMigrator> dbMigrators,
    required List<FeatureKvMigrator> kvMigrators,
    required MigrationDbFactory dbFactory,
  }) : _scopeService = manager,
       _dbMigrators = dbMigrators,
       _kvMigrators = kvMigrators,
       _dbFactory = dbFactory;

  Future<void> migrateDatabase(
    DataScope guestScope,
    DataScope userScope,
  ) async {
    final guestDb = _dbFactory(guestScope);
    final userDb = _dbFactory(userScope);

    await userDb.transaction(() async {
      for (final migrator in _dbMigrators) {
        try {
          await migrator.migrate(guestDb, userDb);
        } catch (e) {
          logger.e('Error migrating module: $e');
        }
      }
    });
  }

  Future<void> migrateKv(DataScope guestScope, DataScope userScope) async {
    // 一般来说迁移的是不同文件, 所以可以并行
    await Future.wait(
      _kvMigrators.map((migrator) async {
        try {
          final guestKv = guestScope.getKv(migrator.kvStoreName);
          final userKv = userScope.getKv(migrator.kvStoreName);

          await migrator.migrate(guestKv, userKv);
        } catch (e) {
          // 单独捕获异常，确保一个失败不会导致整个迁移中断
          logger.e('Error migrating KV ${migrator.kvStoreName}', error: e);
        }
      }),
    );
  }

  @override
  Future<void> migrateFromGuest(UserIdentity userId) async {
    final guestScope = await _scopeService.getGuestScope();
    final userScope = await _scopeService.getUserScope(userId);

    await Future.wait([
      migrateDatabase(guestScope, userScope),
      migrateKv(guestScope, userScope),
    ]);

    // 3. 清理 Guest
    await guestScope.delete();
  }
}
