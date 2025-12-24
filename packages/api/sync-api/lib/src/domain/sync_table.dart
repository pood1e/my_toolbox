import 'package:drift/drift.dart';

/// 所有需要同步的表都混入这个 Mixin
mixin SyncTable on Table {
  TextColumn get id => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
