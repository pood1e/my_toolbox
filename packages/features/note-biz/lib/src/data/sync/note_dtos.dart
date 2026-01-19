import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

import '../../note_domain.dart';

part 'note_dtos.freezed.dart';
part 'note_dtos.g.dart';

@freezed
abstract class DocumentDto with _$DocumentDto implements CocPayload {
  const DocumentDto._();

  const factory DocumentDto({
    required String id,
    required String title,
    required Map<String, dynamic> content,
    required String plainText,
    required DocumentStatus status,
    // --- audit ---
    required int createdAt,
    int? deletedAt,
    // --- CoC ---
    required int version,
    required int updatedAt,
    required int serverUpdatedAt,
    String? conflictRefId,
  }) = _DocumentDto;

  @override
  List<dynamic> get primaryId => [id];

  factory DocumentDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentDtoFromJson(json);
}
