import 'package:drift/drift.dart';

mixin AuditTable on Table {
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
