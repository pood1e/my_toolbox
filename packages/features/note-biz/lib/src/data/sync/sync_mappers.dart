import 'package:drift/drift.dart';

import '../note_database.dart';
import 'note_dtos.dart';

extension DocumentDtoToCompanion on DocumentDto {
  DocumentsCompanion toSyncCompanion() {
    return DocumentsCompanion(
      id: Value(id),
      title: Value(title),
      plainText: Value(plainText),
      content: Value(content),
      status: Value(status),
      createdAt: Value(createdAt),
      deletedAt: Value(deletedAt),
      version: Value(version),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      conflictRefId: Value(conflictRefId),
      isDirty: Value(false),
    );
  }
}

extension DocumentEntityToDto on DocumentEntity {
  DocumentDto toDto() {
    return DocumentDto(
      id: id,
      title: title,
      content: content,
      plainText: plainText,
      status: status,
      createdAt: createdAt,
      version: version,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}
