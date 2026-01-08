import 'package:drift/drift.dart';

import 'memo_database.dart';
import 'memo_dto.dart';

// =============================================================================
// 1. Entity -> DTO (Payload)
// 用于: Sync Handler Collect (上行 Push)
// =============================================================================
extension MemoEntityToPayload on Memo {
  MemoPayload toPayload() {
    return MemoPayload(
      id: id,
      content: content,
      contentHash: contentHash,
      version: version,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
      conflictRefId: conflictRefId,
    );
  }
}

// =============================================================================
// 2. DTO (Payload) -> Entity
// 用于: 内存中快速转换，或者测试
// =============================================================================
extension MemoPayloadToEntity on MemoPayload {
  Memo toEntity({bool isDirty = false}) {
    return Memo(
      id: id,
      content: content,
      contentHash: contentHash,
      version: version,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
      conflictRefId: conflictRefId,
      isDirty: isDirty,
    );
  }
}

// =============================================================================
// 3. DTO (Payload) -> Companion
// 用于: Sync DAO ApplyChanges (下行 Merge/Pull)
// =============================================================================
extension MemoPayloadToCompanion on MemoPayload {
  MemosCompanion toCompanion({bool isDirty = false}) {
    return MemosCompanion(
      id: Value(id),
      content: Value(content),
      contentHash: Value(contentHash),
      // CoC 关键字段
      version: Value(version),
      updatedAt: Value(updatedAt),
      // 服务端的时间
      serverUpdatedAt: Value(serverUpdatedAt),
      conflictRefId: Value(conflictRefId),
      // 默认来自服务端的都是干净的 (false)
      isDirty: Value(isDirty),
    );
  }
}

// =============================================================================
// 4. Entity -> Companion
// 用于: 复制、或者在 DAO 内部进行全量更新
// =============================================================================
extension MemoEntityToCompanion on Memo {
  MemosCompanion toCompanion() {
    return MemosCompanion(
      id: Value(id),
      content: Value(content),
      contentHash: Value(contentHash),
      version: Value(version),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      conflictRefId: Value(conflictRefId),
      isDirty: Value(isDirty),
    );
  }
}
