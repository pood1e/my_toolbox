import 'package:app_core/object.dart';

import '../../standard/standard_sync_payload.dart';

part 'lww_payload.freezed.dart';
part 'lww_payload.g.dart';

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

@freezed
abstract class SimpleLwwAck with _$SimpleLwwAck implements LwwAck {
  const SimpleLwwAck._();

  const factory SimpleLwwAck({
    required String id,
    required int serverUpdatedAt,
  }) = _SimpleLwwAck;

  factory SimpleLwwAck.fromJson(Map<String, dynamic> json) =>
      _$SimpleLwwAckFromJson(json);

  @override
  List<dynamic> get primaryId => [id];
}

@freezed
abstract class SimpleLwwSnapshot
    with _$SimpleLwwSnapshot
    implements LwwSnapshot {
  const SimpleLwwSnapshot._();

  const factory SimpleLwwSnapshot({
    required String id,
    required int updatedAt,
  }) = _SimpleLwwSnapshot;

  @override
  List<dynamic> get primaryId => [id];
}
