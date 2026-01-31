import 'package:app_core/object.dart';

part 'note_domain.freezed.dart';

enum DocumentStatus { inbox, active, archived, trash }

@freezed
abstract class Document with _$Document {
  const Document._();

  const factory Document({
    required String id,
    required String title,
    required Map<String, dynamic> content,
    required DocumentStatus status,
    required bool hasConflict,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Document;
}

@freezed
abstract class Block with _$Block {
  const factory Block({
    required String blockId,
    required String docId,
    required String content,
    required String docTitle
}) = _Block;

}


