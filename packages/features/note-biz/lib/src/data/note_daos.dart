import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../note_domain.dart';
import 'note_database.dart';
import 'sync/note_dtos.dart';
import 'sync/sync_mappers.dart';

part 'note_daos.g.dart';

@DriftAccessor(tables: [Documents, Blocks])
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

  Future<List<TypedResult>> queryBlockContentByKeyword(
    String keyword, {
    int limit = 10,
  }) async {
    final query = selectOnly(blocks)
      ..addColumns([blocks.blockId, blocks.docId, blocks.content])
      ..where(blocks.content.like('%$keyword%'))
      ..limit(limit);
    return await query.get();
  }

  Future<List<TypedResult>> queryAllBlockVector() async {
    final query = selectOnly(blocks)
      ..addColumns([blocks.blockId, blocks.vector])
      ..where(blocks.vector.isNotNull());

    return await query.get();
  }

  Future<List<TypedResult>> queryBlockContentByIds(List<String> ids) async {
    final query = selectOnly(blocks)
      ..addColumns([blocks.blockId, blocks.docId, blocks.content])
      ..where(blocks.blockId.isIn(ids));
    return await query.get();
  }

  Future<List<TypedResult>> queryDocTitleByKeywordOrIds(
    String keyword,
    List<String> docIds,
  ) async {
    // 如果没有查询条件，直接返回空（防止查全表）
    if (docIds.isEmpty && keyword.isEmpty) {
      return [];
    }

    final query = selectOnly(documents)
      ..addColumns([documents.id, documents.title])
      ..where(
        documents.deletedAt.isNull() &
            documents.status.isNotValue(DocumentStatus.trash.index),
      );

    // 构建过滤条件：(ID 在列表中) OR (标题包含关键词)
    Expression<bool> predicate = const Constant(false);

    if (docIds.isNotEmpty) {
      predicate = predicate | documents.id.isIn(docIds);
    }

    if (keyword.isNotEmpty) {
      predicate = predicate | documents.title.like('%$keyword%');
    }

    query.where(predicate);

    return await query.get();
  }
}

@riverpod
Future<DocumentDao> documentDao(Ref ref) async {
  return DocumentDao(await ref.watch(noteDatabaseProvider.future));
}
