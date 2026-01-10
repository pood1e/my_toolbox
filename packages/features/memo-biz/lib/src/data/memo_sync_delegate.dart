import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import 'memo_dao.dart';
import 'memo_database.dart';
import 'memo_dto.dart';
import 'memo_mapper.dart';
import 'memo_table.dart';

part 'memo_sync_delegate.g.dart';

class MemoSyncHandler
    extends
        CocSyncHandler<
          MemoDatabase,
          Memos,
          Memo,
          MemoSnapshot,
          MemoPayload,
          MemoAck,
          MemoDao
        > {
  // ===========================================================================
  // 实体转换 (Mapper)
  // ===========================================================================

  /// Entity (DB) -> Payload (Network Push)
  @override
  MemoPayload fromEntity(Memo entity) {
    return entity.toPayload();
  }

  /// Payload (Network Push) -> Snapshot (Local Memory)
  /// 用于在收到 ACK 时判断数据是否在传输期间被修改
  @override
  MemoSnapshot fromPayload(MemoPayload payload) {
    return MemoSnapshot(id: payload.id, updatedAt: payload.updatedAt);
  }

  // ===========================================================================
  // JSON 序列化胶水代码
  // ===========================================================================

  @override
  MemoAck fromJsonACK(Map<String, dynamic> json) => MemoAck.fromJson(json);

  @override
  MemoPayload fromJsonP(Map<String, dynamic> json) =>
      MemoPayload.fromJson(json);

  @override
  Map<String, dynamic> payloadToJson(MemoPayload payload) => payload.toJson();
}

class MemoSyncDelegate
    extends
        StandardSingleSyncDelegate<
          MemoDao,
          MemoPayload,
          MemoAck,
          CommonSyncRequestPart<MemoPayload>,
          CommonSyncResponsePart<MemoAck, MemoPayload>
        > {
  MemoSyncDelegate({required super.dio, required super.resourceUse})
    : super(handler: MemoSyncHandler());

  @override
  String get resourceId => 'memo';
}

@Riverpod(keepAlive: true)
Future<MemoSyncDelegate> memoSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);

  return MemoSyncDelegate(
    resourceUse: (action) async {
      final sub = ref.listen(memoDaoProvider, (prev, next) {});
      try {
        final dao = await ref.read(memoDaoProvider.future);
        await action(dao);
      } finally {
        sub.close();
      }
    },
    dio: dio,
  );
}
