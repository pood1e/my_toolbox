import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../note_domain.dart';

part 'note_database.g.dart';

@DataClassName('DocumentEntity')
class Documents extends StandardCocTable
    with CreatedAtTableMixin, DeletedAtTableMixin {
  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get content => text().map(const JsonMapConverter())();

  TextColumn get plainText => text().withDefault(const Constant(''))();

  IntColumn get status => intEnum<DocumentStatus>()();

  @override
  Set<Column>? get primaryKey => {id};
}

@DriftDatabase(tables: [Documents])
class NoteDatabase extends _$NoteDatabase with SyncTransactionalDbMixin {
  NoteDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // 1. 创建表结构
      await m.createAll();

      // 2. 创建性能与同步索引
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_document_lww_dirty ON documents(is_dirty)',
      );

      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_document_lww_cursor ON documents(server_updated_at)',
      );
    },
  );
}

@riverpod
Future<NoteDatabase> noteDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(DatabaseId('note', (e) => NoteDatabase(e))).future,
  );
}
