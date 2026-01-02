import 'package:drift/drift.dart';

mixin SoftDeleteSyncTable on Table {
  IntColumn get deletedAt => integer().nullable()();
}

mixin LwwSyncTable on Table {
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
}

mixin LwwWithIdSyncTable on Table {
  TextColumn get id => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}