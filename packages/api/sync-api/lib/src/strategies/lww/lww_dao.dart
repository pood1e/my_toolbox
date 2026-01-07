import 'package:data_api/data_api.dart';

import '../../domain/common_sync_interfaces.dart';
import 'lww_payload.dart';

abstract class LwwDao<
  E,
  S extends LwwSnapshot,
  ACK extends LwwAck,
  P extends LwwPayload
>
    implements
        DirtySelectSyncDao<E>,
        MaxCursorSyncDao,
        PrimaryKeyDao,
        AckPatchSyncDao<S, ACK> {
  Future<void> applyChanges(List<P> payloads);
}
