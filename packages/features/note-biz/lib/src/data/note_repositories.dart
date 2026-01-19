import 'package:app_core/di.dart';

import '../note_domain.dart';
import 'impl/document_repository_impl.dart';
import 'note_daos.dart';

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
}

@riverpod
Future<DocumentRepository> documentRepository(Ref ref) async {
  return DocumentRepositoryImpl(
    dao: await ref.watch(documentDaoProvider.future),
  );
}
