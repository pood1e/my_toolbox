// File: strategies/delta/delta_sync_handler.dart

import 'package:network_api/network_api.dart';

import '../../standard/sync_handler.dart';
import 'delta_mixin.dart';
import 'delta_payload.dart';

abstract class DeltaSyncHandler<
  DAO extends DeltaDao2PCMixin<dynamic, dynamic, E, dynamic, dynamic>,
  E,
  PUSH,
  PULL
>
    extends SyncHandler<DAO, DeltaSyncRequestPart<PUSH>, List<PULL>> {
  final DeviceIdService _deviceIdService;

  DeltaSyncHandler({required DeviceIdService deviceIdService})
    : _deviceIdService = deviceIdService;

  PUSH toPushDTO(E entity);

  @override
  Future<DeltaSyncRequestPart<PUSH>> collect(DAO dao) async {
    return await dao.lockAndGetPayload(
      await _deviceIdService.getDeviceId(),
      toPushDTO,
    );
  }

  @override
  Future<void> merge(
    DAO dao,
    List<PULL> resp,
    DeltaSyncRequestPart<PUSH> sentReq,
  ) async {
    // 1. 处理下行数据 (由子类实现具体的 Upsert 逻辑)
    if (resp.isNotEmpty) {
      await applyRemotePatches(dao, resp);
    }

    // 2. 处理上行确认 (Commit)
    // 检查 sentReq 中是否包含 payload，且只有当网络请求无误时才会走到这里
    if (sentReq.deltas?.isNotEmpty ?? false) {
      await dao.onPushSuccess();
    }
  }

  // 留给子类实现具体的 Merge 逻辑
  Future<void> applyRemotePatches(DAO dao, List<PULL> patches);
}
