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
    await _dao.softDelete([id], nowMs);
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
}
