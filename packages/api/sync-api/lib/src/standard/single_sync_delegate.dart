import 'package:app_core/object.dart';

import 'sync_delegate_base.dart';
import 'sync_handler.dart';

/// 单一同步委托
abstract class SingleSyncDelegate<Res extends TransactionalResource, Req, Resp>
    extends SyncDelegateBase<Res, Req, Resp> {
  final SyncHandler<Res, Req, Resp> handler;

  SingleSyncDelegate({
    required super.dio,
    required super.resourceUse,
    required this.handler,
  });

  @override
  Future<void> sync() async {
    await resourceUse((resource) async {
      // 1. Collect
      final request = await resource.syncTranscation(() async {
        return await handler.collect(resource);
      });

      // 2. Transport (直接发送 Request 对象)
      final dioResponse = await dio.post(
        '/sync/$resourceId',
        data: handler.reqToJson(request),
      );

      final rawData = R.fromJson(dioResponse.data, (e) => e).data;
      if (rawData == null) return;

      // 3. Deserialize
      final response = handler.respFromJson(rawData);

      // 4. Merge
      await resource.syncTranscation(() async {
        await handler.merge(resource, response, request);
      });

      // 5. Cleanup
      await resource.syncTranscation(() async {
        await handler.onPostSync(resource);
      });
    });
  }
}
