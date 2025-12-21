import 'package:auth_biz/auth_biz.dart';
import 'package:drift/drift.dart';

abstract class DatabaseMigration {
  Future<void> onConflict(QueryExecutor src, QueryExecutor dst);
}

abstract class DatabaseService {
  QueryExecutor openGlobalDatabase(String db);

  QueryExecutor openUserDatabase(String db, UserIdentity userId);

  QueryExecutor openGuestDatabase(String db);

  Future<void> migrateFromGuest(
    String db,
    UserIdentity userId,
    DatabaseMigration migration, [
    bool deleteGuest = true,
  ]);

  Future<void> clearGuest();

  Future<void> clearUser(UserIdentity userId);
}
