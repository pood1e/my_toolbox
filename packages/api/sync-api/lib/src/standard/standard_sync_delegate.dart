import '../domain/common_sync_interfaces.dart';
import 'composite_sync_delegate.dart';
import 'single_sync_delegate.dart';
import 'standard_sync_payload.dart';
import 'sync_delegate_base.dart';
import 'sync_handler.dart';

/// 辅助基类：适用于使用 SyncRequest 接口的 Handler
mixin StandardSyncHandlerMixin<
  Res,
  P,
  ACK extends StandardSyncResponseAck,
  Req extends StandardSyncRequestPart<P>,
  Resp extends StandardSyncResponsePart<ACK, P>
>
    on SyncHandler<Res, Req, Resp> {
  Map<String, dynamic> payloadToJson(P payload);

  @override
  Map<String, dynamic> reqToJson(Req req) {
    return req.toJson(payloadToJson);
  }

  @override
  Future<void> onPostSync(Res resource) async {
    if (resource is SoftDeleteSyncDao) {
      await (resource as SoftDeleteSyncDao).gc();
    }
  }
}

abstract class StandardSyncHandler<
  Res,
  P,
  ACK extends StandardSyncResponseAck,
  Req extends StandardSyncRequestPart<P>,
  Resp extends StandardSyncResponsePart<ACK, P>
>
    extends SyncHandler<Res, Req, Resp>
    with StandardSyncHandlerMixin<Res, P, ACK, Req, Resp> {}

abstract class StandardSingleSyncDelegate<
  Res extends TransactionalResource,
  P,
  ACK extends StandardSyncResponseAck,

  Req extends StandardSyncRequestPart<P>,
  Resp extends StandardSyncResponsePart<ACK, P>
>
    extends SingleSyncDelegate<Res, Req, Resp> {
  StandardSingleSyncDelegate({
    required super.dio,
    required super.resourceUse,
    required StandardSyncHandler<Res, P, ACK, Req, Resp> handler,
  }) : super(handler: handler);
}

abstract class StandardCompositeSyncHandler<
  Res extends TransactionalResource,
  P,
  ACK extends StandardSyncResponseAck,

  Req extends StandardSyncRequestPart<P>,
  Resp extends StandardSyncResponsePart<ACK, P>
>
    extends CompositeSyncHandler<Res, Req, Resp>
    with StandardSyncHandlerMixin<Res, P, ACK, Req, Resp> {}

abstract class StandardCompositeSyncDelegate<Tr extends TransactionalResource>
    extends CompositeSyncDelegate<Tr> {
  StandardCompositeSyncDelegate({
    required super.dio,
    required super.resourceUse,
    required List<StandardCompositeSyncHandler> handlers,
  }) : super(handlers: handlers);
}
