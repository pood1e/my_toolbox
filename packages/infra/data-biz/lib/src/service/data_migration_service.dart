import 'package:auth_api/auth_api.dart';

abstract class DataMigrationService {
  Future<void> migrateFromGuest(UserIdentity userId);
  Future<bool> hasAnyNeedMigrate();
}
