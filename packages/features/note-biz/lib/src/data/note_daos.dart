import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../note_domain.dart';
import 'note_database.dart';
import 'sync/note_dtos.dart';
import 'sync/sync_mappers.dart';

part 'note_daos.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentDao
    extends
        StandardCocDao<
          NoteDatabase,
          Documents,
          DocumentEntity,
          SimpleCocSnapshot,
          SimpleCocAck,
          DocumentDto
        >
    with
        _$DocumentDaoMixin,
        GetOneDaoMixin<NoteDatabase, Documents, DocumentEntity> {
  DocumentDao(super.attachedDatabase);

  @override
  TableInfo<Documents, DocumentEntity> get table => documents;

  @override
  Insertable<DocumentEntity> toCocCompanion(DocumentDto payload) {
    return payload.toSyncCompanion();
  }

  Stream<List<DocumentEntity>> watchByStatus(DocumentStatus status) {
    final query = select(documents)
      ..where((t) => t.status.equals(status.index) & t.deletedAt.isNull())
      ..orderBy([
        // 按更新时间倒序 (最近修改的在上面)
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch();
  }
}

@riverpod
Future<DocumentDao> documentDao(Ref ref) async {
  return DocumentDao(await ref.watch(noteDatabaseProvider.future));
}
