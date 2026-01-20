import 'package:app_core/logger.dart';
import 'package:drift/drift.dart';

import '../../note_domain.dart';
import '../note_daos.dart';
import '../note_database.dart';
import '../note_mappers.dart';
import '../note_repositories.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentDao _dao;

  DocumentRepositoryImpl({required DocumentDao dao}) : _dao = dao;

  @override
  Stream<List<Document>> watchDocumentsByStatus(DocumentStatus status) {
    return _dao
        .watchByStatus(status)
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Document?> getDocument(String id) async {
    final result = await _dao.getById([id]);
    return result?.toDomain();
  }

  @override
  Future<void> createDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
    required int nowMs,
  }) async {
    final companion = DocumentsCompanion.insert(
      id: id,
      title: Value(title),
      content: content,
      status: DocumentStatus.inbox,
      createdAt: Value(nowMs),
      updatedAt: nowMs,
      isDirty: Value(true),
    );

    await _dao.createIfNotExist(companion);
  }

  @override
  Future<void> softDelete(String id, int nowMs) async {
    await _dao.transaction(() async {
      await _dao.softDelete([id], nowMs);
      await (_dao.delete(_dao.blocks)..where((t) => t.docId.equals(id))).go();
    });
  }

  @override
  Future<void> updateDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
    required int nowMs,
  }) async {
    final companion = DocumentsCompanion(
      title: Value(title),
      content: Value(content),
      updatedAt: Value(nowMs),
      isDirty: Value(true),
    );

    await _dao.updateIfExist([id], companion);
  }

  @override
  Future<void> updateStatus(String id, DocumentStatus status, int nowMs) async {
    final companion = DocumentsCompanion(
      status: Value(status),
      updatedAt: Value(nowMs),
      isDirty: Value(true),
    );
    await _dao.updateIfExist([id], companion);
  }

  @override
  Future<void> updateBlocks(List<UpdateBlockParam> params) async {
    // 不再在最外层开启大事务
    for (final param in params) {
      try {
        await _dao.transaction(() async {
          // ---------------------------------------------------------
          // 1. 乐观锁检查 (Check Version)
          // ---------------------------------------------------------
          final doc = await (_dao.select(
            _dao.documents,
          )..where((t) => t.id.equals(param.docId))).getSingleOrNull();

          // 如果文档被删了，跳过
          if (doc == null || doc.deletedAt != null) return;

          // 校验版本：如果时间戳不匹配，说明文档已过时，放弃本次更新
          if (doc.updatedAt != param.updatedAt) {
            logger.w('⚠️ [Skipped] Doc ${param.docId} updated concurrently.');
            return; // 退出当前事务，不执行写操作
          }

          // ---------------------------------------------------------
          // 2. 执行更新 (Atomic: Delete + Insert + UpdateStatus)
          // ---------------------------------------------------------

          // A. 删除旧 Block
          await (_dao.delete(
            _dao.blocks,
          )..where((t) => t.docId.equals(param.docId))).go();

          // B. 插入新 Block
          if (param.companions.isNotEmpty) {
            await _dao.batch((batch) {
              batch.insertAll(
                _dao.blocks,
                param.companions,
                mode: InsertMode.insertOrReplace,
              );
            });
          }

          // C. 标记 Document 为已索引 (isIndexed = true)
          // 依然不能改 updatedAt，因为这是在同步旧版本的状态
          await (_dao.update(_dao.documents)
                ..where((t) => t.id.equals(param.docId)))
              .write(const DocumentsCompanion(isIndexed: Value(true)));
        });
      } catch (e) {
        // [关键] 捕获单个文档更新的异常，防止打断整个循环
        logger.e('❌ Failed to update blocks for ${param.docId}: $e');
        // 可以在这里上报错误监控 (Sentry/Firebase)
      }
    }
  }

  @override
  Future<List<BlockVector>> getAllBlockVectors() async {
    final rows = await _dao.queryAllBlockVector();

    return rows.map((row) {
      final id = row.read(_dao.blocks.blockId)!;

      // 2. 获取 Vector (修复运行时类型错误)
      // 使用 dynamic 绕过检查，读取出来的 rawValue 是 String (JSON)
      final rawValue = (row as dynamic).read(_dao.blocks.vector);

      // 3. 手动应用转换器：String -> List<double>
      // 访问列定义中的 converter 属性来进行转换
      final List<double> vector = _dao.blocks.vector.converter.fromSql(
        rawValue as String,
      );

      return BlockVector(blockId: id, vector: vector);
    }).toList();
  }

  @override
  Future<List<BlockContent>> getByIds(List<String> blockIds) async {
    final rows = await _dao.queryBlockContentByIds(blockIds);
    return rows.map((row) {
      return BlockContent(
        id: row.read(_dao.blocks.blockId)!,
        docId: row.read(_dao.blocks.docId)!,
        content: row.read(_dao.blocks.content)!,
      );
    }).toList();
  }

  @override
  Future<List<BlockContent>> queryBlocksByKeyword(String keyword) async {
    final rows = await _dao.queryBlockContentByKeyword(keyword);
    return rows.map((row) {
      return BlockContent(
        id: row.read(_dao.blocks.blockId)!,
        docId: row.read(_dao.blocks.docId)!,
        content: row.read(_dao.blocks.content)!,
      );
    }).toList();
  }

  @override
  Future<List<DocTitle>> queryDocumentTitleOrIds(
    String keyword,
    List<String> ids,
  ) async {
    final rows = await _dao.queryDocTitleByKeywordOrIds(keyword, ids);
    return rows.map((row) {
      return DocTitle(
        id: row.read(_dao.documents.id)!,
        title: row.read(_dao.documents.title)!,
      );
    }).toList();
  }
}
