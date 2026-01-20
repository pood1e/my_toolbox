import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../note_domain.dart';
import 'impl/document_repository_impl.dart';
import 'note_daos.dart';
import 'note_database.dart';

part 'note_repositories.freezed.dart';
part 'note_repositories.g.dart';

/// 文档仓库抽象接口
/// 职责：定义对 Document 实体的所有操作契约
abstract class DocumentRepository {
  Stream<List<Document>> watchDocumentsByStatus(DocumentStatus status);

  Future<Document?> getDocument(String id);

  Future<void> createDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
    required int nowMs,
  });

  Future<void> updateDocument({
    required String id,
    required String title,
    required Map<String, dynamic> content,
    required int nowMs,
  });

  Future<void> updateStatus(String id, DocumentStatus status, int nowMs);

  Future<void> softDelete(String id, int nowMs);

  // --- block ---
  Future<void> updateBlocks(List<UpdateBlockParam> params);

  Future<List<BlockContent>> queryBlocksByKeyword(String keyword);

  Future<List<DocTitle>> queryDocumentTitleOrIds(
    String keyword,
    List<String> ids,
  );

  Future<List<BlockVector>> getAllBlockVectors();

  Future<List<BlockContent>> getByIds(List<String> blockIds);
}

@freezed
abstract class UpdateBlockParam with _$UpdateBlockParam {
  const factory UpdateBlockParam({
    required String docId,
    required int updatedAt,
    required List<BlocksCompanion> companions,
  }) = _UpdateBlockParam;
}

@freezed
abstract class BlockVector with _$BlockVector {
  const factory BlockVector({
    required String blockId,
    required List<double> vector,
  }) = _BlockVector;
}

@freezed
abstract class DocTitle with _$DocTitle {
  const factory DocTitle({required String id, required String title}) =
      _DocTitle;
}

@freezed
abstract class BlockContent with _$BlockContent {
  const factory BlockContent({
    required String id,
    required String docId,
    required String content,
  }) = _BlockContent;
}

@riverpod
Future<DocumentRepository> documentRepository(Ref ref) async {
  return DocumentRepositoryImpl(
    dao: await ref.watch(documentDaoProvider.future),
  );
}
