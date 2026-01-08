import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

class Memos extends Table
    with
        IsDirtySyncTableMixin,
        CursorSyncTableMixin,
        CreatedAtTableMixin,
        UpdatedAtTableMixin,
        DeletedAtTableMixin,
        CocTableMixin {
  TextColumn get id => text()();

  TextColumn get content => text()();

  TextColumn get contentHash => text()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column>? get primaryKey => {id};
}
