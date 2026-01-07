// File: strategies/coc/coc_dao.dart
import 'package:data_api/data_api.dart';

import '../../domain/common_sync_interfaces.dart';
import 'coc_payload.dart';

/// CoC DAO 接口定义
abstract class CocDao<
  E,
  S extends CocSnapshot,
  ACK extends CocAck,
  P extends CocPayload
>
    implements
        DirtySelectSyncDao<E>,
        MaxCursorSyncDao,
        PrimaryKeyDao,
        AckPatchSyncDao<S, ACK> {
  Future<void> applyChanges(List<P> payloads);
}
