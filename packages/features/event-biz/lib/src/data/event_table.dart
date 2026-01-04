import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

@DataClassName('EventEntity')
class Events extends CoreSyncTable with AuditTable {
  TextColumn get name => text()();

  IntColumn get timestamp => integer()();

  TextColumn get source => text()();
}
