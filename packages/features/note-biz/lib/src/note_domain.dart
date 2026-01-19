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
