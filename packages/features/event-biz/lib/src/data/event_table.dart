import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

@DataClassName('EventEntity')
class Events extends Table
    with
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        UpdatedAtTableMixin,
        LwwTableMixin,
        DeletedAtTableMixin,
        CreatedAtTableMixin {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get timestamp => integer()();

  TextColumn get source => text()();

  @override
  Set<Column>? get primaryKey => {id, source};
}
