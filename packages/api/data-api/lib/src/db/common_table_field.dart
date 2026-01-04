import 'package:drift/drift.dart';

mixin AuditTable on Table {
  IntColumn get createdAt => integer().clientDefault(
    () => DateTime.now().toUtc().millisecondsSinceEpoch,
  )();

  IntColumn get updatedAt => integer()();
}
