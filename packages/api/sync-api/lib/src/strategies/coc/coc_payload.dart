import 'package:app_core/object.dart';

import '../../standard/standard_sync_payload.dart';

part 'coc_payload.freezed.dart';
part 'coc_payload.g.dart';

/// CoC 策略的 Payload 接口 (数据传输对象 DTO)
abstract class CocPayload {
  List<dynamic> get primaryId;

  int get updatedAt;

  int get serverUpdatedAt;

  int get version;

  String? get conflictRefId;
}

/// CoC 策略的快照 (用于并发安全检查)
/// 必须包含 updatedAt，以便在 ACK 回来时检查本地数据是否被修改过
abstract class CocSnapshot extends SyncRequestSnapshot {
  int get updatedAt;
}

/// CoC 策略的 ACK
abstract class CocAck extends StandardSyncResponseAck {
  int get serverUpdatedAt;

  int get version;
}

@freezed
abstract class SimpleCocSnapshot
    with _$SimpleCocSnapshot
    implements CocSnapshot {
  const SimpleCocSnapshot._();

  const factory SimpleCocSnapshot({
    required String id,
    required int updatedAt,
  }) = _SimpleCocSnapshot;

  @override
  List<dynamic> get primaryId => [id];
}

@freezed
abstract class SimpleCocAck with _$SimpleCocAck implements CocAck {
  const SimpleCocAck._();

  const factory SimpleCocAck({
    required String id,
    required int serverUpdatedAt,
    required int version,
  }) = _SimpleCocAck;

  factory SimpleCocAck.fromJson(Map<String, dynamic> json) =>
      _$SimpleCocAckFromJson(json);

  @override
  List<dynamic> get primaryId => [id];
}
