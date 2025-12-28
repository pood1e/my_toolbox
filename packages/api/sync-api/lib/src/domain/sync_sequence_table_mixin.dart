import 'package:drift/drift.dart';

mixin SyncSequenceTableMixin on Table {
  TextColumn get moduleId => text()();

  IntColumn get sequence => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {moduleId};
}
