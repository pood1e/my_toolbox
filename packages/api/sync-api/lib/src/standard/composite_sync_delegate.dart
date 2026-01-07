import 'package:app_core/object.dart';

import 'sync_delegate_base.dart';
import 'sync_handler.dart';

/// 聚合同步委托
/// 支持在一个 API 接口中同步多个业务模块
abstract class CompositeSyncDelegate<Tr extends TransactionalResource>
    extends SyncDelegateBase<Tr, dynamic, dynamic>
    implements ResourceSelector<Tr, dynamic> {
  // 支持异构的 Handlers 列表
  // 由于泛型不同，这里只能存为基础接口类型
  final List<CompositeSyncHandler> handlers;

  CompositeSyncDelegate({
    required super.dio,
    required super.resourceUse,
    required this.handlers,
  });

  @override
  Future<void> sync() async {
    await resourceUse((tr) async {
      // =======================================================================
      // 1. Gather (并行收集)
      // =======================================================================
      final requestMap = <String, dynamic>{};

      // 临时保存每个 Handler 产生的 Request 对象，供后续 Merge 使用
      // Key: Handler.key, Value: Req Object
      final sentRequests = <String, dynamic>{};

      await tr.syncTranscation(() async {
        for (final handler in handlers) {
          final req = await handler.collect(selectResource(tr, handler.key));

          // 只有当有数据或者是 Pull 模式(req不为空)时才放入请求体
          if (req != null) {
            sentRequests[handler.key] = req;
            requestMap[handler.key] = handler.reqToJson(req);
          }
        }
      });

      // 如果没有任何 Handler 产生数据，且不需要强制 Pull，可以在这里 return
      if (requestMap.isEmpty) return;

      // =======================================================================
      // 2. Transport (一次请求)
      // =======================================================================
      final dioResponse = await dio.post(
        apiPath,
        data: requestMap, // 发送聚合 JSON
      );

      final rawRootData = R.fromJson(dioResponse.data, (e) => e).data;
      if (rawRootData == null || rawRootData is! Map) return;

      // =======================================================================
      // 3. Distribute & Merge (分发与合并)
      // =======================================================================
      await tr.syncTranscation(() async {
        for (final handler in handlers) {
          final key = handler.key;

          // 从大 JSON 中取出属于该 Handler 的片段
          final rawFragment = rawRootData[key];
          final sentReq = sentRequests[key];

          // 如果服务端返回了该片段的数据
          if (rawFragment != null) {
            // 反序列化
            final resp = handler.respFromJson(rawFragment);
            // 执行合并
            await handler.merge(selectResource(tr, handler.key), resp, sentReq);
          }
        }
      });

      // =======================================================================
      // 4. Cleanup (清理)
      // =======================================================================
      await tr.syncTranscation(() async {
        for (final handler in handlers) {
          // 只有参与了本次 Sync (或者策略决定每次都 GC) 才执行
          // 这里默认都执行，由 Handler 内部决定是否轻量化
          await handler.onPostSync(selectResource(tr, handler.key));
        }
      });
    });
  }
}
