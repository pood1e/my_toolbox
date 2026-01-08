
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

/// 快照 (用于并发安全检查)
@freezed
abstract class MemoSnapshot with _$MemoSnapshot implements CocSnapshot {
  const MemoSnapshot._();

  const factory MemoSnapshot({
    required String id,
    required int updatedAt,
  }) = _MemoSnapshot;

  @override
  List<dynamic> get primaryId => [id];
}

/// 服务端响应 ACK
@freezed
abstract class MemoAck with _$MemoAck implements CocAck {
  const MemoAck._();

  const factory MemoAck({
    required String id,
    required int version,
    required int serverUpdatedAt,
  }) = _MemoAck;

  @override
  List<dynamic> get primaryId => [id];

  factory MemoAck.fromJson(Map<String, dynamic> json) =>
      _$MemoAckFromJson(json);
}