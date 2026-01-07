import 'package:drift/drift.dart';

mixin CreatedAtTableMixin on Table {
  IntColumn get createdAt => integer().clientDefault(
    () => DateTime.now().toUtc().millisecondsSinceEpoch,
  )();
}

mixin UpdatedAtTableMixin on Table {
  IntColumn get updatedAt => integer()();
}

mixin DeletedAtTableMixin on Table {
  IntColumn get deletedAt => integer().nullable()();
}
