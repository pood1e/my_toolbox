import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'event_entity.dart';

@UseRowClass(EventEntity)
class Events extends LwwTable with AuditTable, SoftDeleteTable {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get timestamp => integer()();

  TextColumn get source => text()();

  @override
  Set<Column>? get primaryKey => {id, source};
}
