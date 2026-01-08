import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

class Memos extends Table
    with
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        UpdatedAtTableMixin,
        CocTableMixin {
  TextColumn get id => text()();

  TextColumn get content => text()();

  TextColumn get contentHash => text()();

  @override
  Set<Column>? get primaryKey => {id};
}
