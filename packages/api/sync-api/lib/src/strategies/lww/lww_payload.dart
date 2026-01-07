import '../../standard/standard_sync_payload.dart';

abstract class LwwPayload {
  List<dynamic> get primaryId;

  int get updatedAt;

  int get serverUpdatedAt;
}

abstract class LwwSnapshot extends SyncRequestSnapshot {
  int get updatedAt;
}

abstract class LwwAck extends StandardSyncResponseAck {
  int get serverUpdatedAt;
}
