import 'package:drift/drift.dart';

mixin AuditTable on Table {
  IntColumn get createdAt => integer().clientDefault(
    () => DateTime.now().toUtc().millisecondsSinceEpoch,
  )();

  IntColumn get updatedAt => integer()();
}

mixin SoftDeleteTable on Table {
  IntColumn get deletedAt => integer().nullable()();
}

mixin AuditEntity {
  int get createdAt;
  int get updatedAt;
}

mixin SoftDeleteEntity {
  int? get deletedAt;
}