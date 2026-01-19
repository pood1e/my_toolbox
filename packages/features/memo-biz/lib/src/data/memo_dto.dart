import 'package:app_core/object.dart';
import 'package:framework_api/framework_api.dart';

part 'memo_dto.freezed.dart';
part 'memo_dto.g.dart';

/// 上行/下行 传输对象
@freezed
abstract class MemoPayload with _$MemoPayload implements CocPayload {
  const MemoPayload._();

  const factory MemoPayload({
    required String id,
    required String content,
    required String contentHash,
    required bool isArchived,
    required int createdAt,
    int? deletedAt,
    // --- CoC 必需字段 ---
    required int version,
    required int updatedAt,
    required int serverUpdatedAt,
    String? conflictRefId,
  }) = _MemoPayload;

  @override
  List<dynamic> get primaryId => [id];

  factory MemoPayload.fromJson(Map<String, dynamic> json) =>
      _$MemoPayloadFromJson(json);
}
