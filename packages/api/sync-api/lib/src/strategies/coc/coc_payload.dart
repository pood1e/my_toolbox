import '../../standard/standard_sync_payload.dart';

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
