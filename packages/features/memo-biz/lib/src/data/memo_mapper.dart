import 'package:drift/drift.dart';

import '../memo_domain.dart';
import 'memo_database.dart';
import 'memo_dto.dart';

// =============================================================================
// 1. Entity (DB) -> Domain (UI)
// =============================================================================
extension MemoEntityToDomain on Memo {
  MemoDomain toDomain() {
    return MemoDomain(
      id: id,
      content: content,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      // 映射
      isArchived: isArchived,
      // 映射
      isDirty: isDirty,
    );
  }
}

// =============================================================================
// 2. Entity (DB) -> DTO (Network Push)
// 用于: SyncHandler.collect
// =============================================================================
extension MemoEntityToPayload on Memo {
  MemoPayload toPayload() {
    return MemoPayload(
      id: id,
      content: content,
      contentHash: contentHash,
      // 新增映射
      isArchived: isArchived,
      createdAt: createdAt,
      deletedAt: deletedAt,
      // CoC
      version: version,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
      conflictRefId: conflictRefId,
    );
  }
}

// =============================================================================
// 3. DTO (Network Pull) -> Companion (DB Write)
// 用于: SyncDao.toCocCompanion (ApplyChanges)
// =============================================================================
extension MemoPayloadToCompanion on MemoPayload {
  MemosCompanion toCompanion({bool isDirty = false}) {
    return MemosCompanion(
      id: Value(id),
      content: Value(content),
      contentHash: Value(contentHash),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      deletedAt: Value(deletedAt),
      // CoC
      version: Value(version),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      conflictRefId: Value(conflictRefId),
      isDirty: Value(isDirty),
    );
  }
}
