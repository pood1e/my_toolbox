import 'package:auth_biz/auth_biz.dart';

abstract class DataMigrationService {
  Future<void> migrateFromGuest(UserIdentity userId);
}
