import 'package:core/di.dart';
import 'package:core/object.dart';

import 'domain/migrator.dart';

part 'need_override_providers.g.dart';

@Riverpod(keepAlive: true)
MigrationDbFactory migrationDatabaseFactory(Ref ref) {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
List<FeatureDbMigrator> dbMigrationRegistry(Ref ref) {
  return [];
}

@Riverpod(keepAlive: true)
List<FeatureKvMigrator> kvMigrationRegistry(Ref ref) {
  return [];
}
