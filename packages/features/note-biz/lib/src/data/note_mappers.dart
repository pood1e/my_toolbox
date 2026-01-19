import '../note_domain.dart';
import 'note_database.dart';

extension DocumentEntityToDomain on DocumentEntity {
  Document toDomain() {
    return Document(
      id: id,
      title: title,
      content: content,
      status: status,
      hasConflict: conflictRefId != null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}