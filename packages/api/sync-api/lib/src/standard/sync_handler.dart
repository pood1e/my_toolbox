

/// [Res]: 资源 (DAO/DB)
/// [Req]: 该 Handler 对应的请求体片段
/// [Resp]: 该 Handler 对应的响应体片段
abstract class SyncHandler<Res, Req, Resp> {
  // --- 阶段 1: 收集 ---
  Future<Req> collect(Res dao);

  // --- 阶段 2: 序列化 (片段) ---
  /// 将 Req 转为 JSON 片段
  Map<String, dynamic> reqToJson(Req req);

  // --- 阶段 3: 反序列化 (片段) ---
  /// 将 JSON 片段转为 Resp
  Resp respFromJson(Object? json);

  // --- 阶段 4: 合并 ---
  Future<void> merge(Res resource, Resp resp, Req sentReq);

  // --- 阶段 5: 清理 ---
  Future<void> onPostSync(Res resource) async {}
}

/// 聚合同步处理器接口
abstract class CompositeSyncHandler<Res, Req, Resp>
    extends SyncHandler<Res, Req, Resp> {
  String get key;
}
