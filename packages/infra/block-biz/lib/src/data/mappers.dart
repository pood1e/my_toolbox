import 'package:drift/drift.dart';

import '../domain/node.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/property_descriptor.dart';
import '../repository/property_config_repository.dart';
import '../ui/state/property_state.dart';
import 'node_database.dart';

/// todo: mapper逻辑按层次切分

// --- Node Mapper ---
extension NodeEntityToDomain on NodeEntity {
  Node toDomain() => Node(id: id);
}

extension NodeDomainToCompanion on Node {
  NodesCompanion toCompanion() => NodesCompanion(id: Value(id));
}

extension PropertyEntityToDomain on PropertyEntity {
  Property toDomain(StorageType type) {
    // 构建 key
    final storageKey = PropertyStorageKey(
      nodeId: nodeId,
      defId: defId,
      type: type,
    );

    // 根据类型获取对应的值
    final rawValue = switch (type) {
      StorageType.bool => valBool,
      StorageType.int => valInt,
      StorageType.real => valReal,
      StorageType.text => valText,
      StorageType.json => valJson,
    };

    return Property(
      key: storageKey,
      value: switch (valueStatus) {
        ValueStatus.normal => PropertyValue.success(value: rawValue),
        ValueStatus.dirty => PropertyValue.dirty(value: rawValue),
        ValueStatus.error => PropertyValue.error(error: errorType!),
      },
    );
  }
}

extension PropertyDomainToCompanion on Property {
  PropertiesCompanion toCompanion() {
    // 获取基础 companion
    final baseCompanion = PropertiesCompanion(
      nodeId: Value(key.nodeId),
      defId: Value(key.defId),
    );

    // 根据 Property 类型设置状态和值
    final (valueStatus, errorType, rawValue) = switch (value) {
      SuccessPropertyValue(:final value) => (
        ValueStatus.normal,
        null as ComputeError?,
        value,
      ),
      DirtyPropertyValue(:final value) => (
        ValueStatus.dirty,
        null as ComputeError?,
        value,
      ),
      ErrorPropertyValue(:final error) => (
        ValueStatus.error,
        error,
        null as dynamic,
      ),
    };

    // 添加状态信息
    final statusCompanion = baseCompanion.copyWith(
      valueStatus: Value(valueStatus),
      errorType: Value(errorType),
    );

    // 根据存储类型设置对应的值字段
    return switch (key.type) {
      StorageType.bool => statusCompanion.copyWith(valBool: Value(rawValue)),
      StorageType.int => statusCompanion.copyWith(valInt: Value(rawValue)),
      StorageType.real => statusCompanion.copyWith(valReal: Value(rawValue)),
      StorageType.text => statusCompanion.copyWith(valText: Value(rawValue)),
      StorageType.json => statusCompanion.copyWith(valJson: Value(rawValue)),
    };
  }
}

extension PropertyConfigMapper on List<PropertyAtomConfigEntity> {
  /// 转换为纯记录列表 (用于 Diff 或内部处理)
  List<PropertyConfigRecord> toRecords() {
    return map(
      (r) => PropertyConfigRecord(
        configKey: r.configKey,
        mapKey: r.mapKey,
        targetNodeId: r.targetNodeId,
        targetDefId: r.targetDefId,
        config: r.config,
        affectValue: r.affectValue,
      ),
    ).toList();
  }

  /// 转换为完整的 Domain 对象
  PropertyConfig toDomain(PropertyKey key) {
    return PropertyConfig(key: key, records: toRecords());
  }
}

extension PropertyConfigDiff on PropertyConfig {
  /// 对比旧记录，计算变更集
  List<ParticalConfigChange> diff(List<PropertyConfigRecord> oldRecords) {
    final changes = <ParticalConfigChange>[];
    final newRecords = records; // 当前 Domain 中的记录

    // 建立索引: (configKey, mapKey) -> Record
    final oldMap = {for (final r in oldRecords) (r.configKey, r.mapKey): r};
    final newMap = {for (final r in newRecords) (r.configKey, r.mapKey): r};

    // 1. Insert & Update
    for (final entry in newMap.entries) {
      final id = entry.key;
      final newRecord = entry.value;
      final oldRecord = oldMap[id];

      final partialKey = ParticialUpdateConfigKey(
        nodeId: key.nodeId,
        refId: key.defId,
        configKey: id.$1,
        mapKey: id.$2,
      );

      final partialRecord = ParticalUpdateConfigRecord(
        targetNodeId: newRecord.targetNodeId,
        targetDefId: newRecord.targetDefId,
        config: newRecord.config,
        affectValue: newRecord.affectValue,
      );

      if (oldRecord == null) {
        changes.add(ParticalConfigChange.insert(partialKey, partialRecord));
      } else if (newRecord != oldRecord) {
        changes.add(ParticalConfigChange.update(partialKey, partialRecord));
      }
    }

    // 2. Delete
    for (final entry in oldMap.entries) {
      if (!newMap.containsKey(entry.key)) {
        changes.add(
          ParticalConfigChange.delete(
            ParticialUpdateConfigKey(
              nodeId: key.nodeId,
              refId: key.defId,
              configKey: entry.key.$1,
              mapKey: entry.key.$2,
            ),
          ),
        );
      }
    }
    return changes;
  }
}

/// 3. 业务逻辑: 判断是否脏 (Affect Value Logic)
extension PariticalConfigDirtyCheck on ParticalConfigChange {
  /// 根据数据库中的旧 affectValue 判断是否产生影响
  /// [oldAffectValue]:
  /// - Insert 时传 null
  /// - Update/Delete 时传 DB 中的旧值
  bool isDirty(bool? oldAffectValue) {
    return map(
      insert: (c) {
        // Insert: 只有新值为 true 时影响
        // old(null) -> new(true) : Dirty
        // old(null) -> new(false): Clean
        return c.record.affectValue;
      },
      update: (c) {
        // Update: 只要有一方为 true，就可能涉及值的改变或状态切换
        // old(true)  -> new(true)  : Dirty (值可能变)
        // old(false) -> new(true)  : Dirty (激活)
        // old(true)  -> new(false) : Dirty (失活)
        // old(false) -> new(false) : Clean
        final newAffect = c.record.affectValue;
        return (oldAffectValue == true) || newAffect;
      },
      delete: (c) {
        // Delete: 只有旧值为 true 时影响
        // old(true)  -> delete : Dirty
        // old(false) -> delete : Clean
        return oldAffectValue == true;
      },
    );
  }
}

extension PropertyDomainToState on Property? {
  PropertyState toState() {
    if (this == null) {
      return PropertyState.uninitialized();
    }
    return switch (this!.value) {
      SuccessPropertyValue(:final value) => PropertyState.idle(value: value),
      DirtyPropertyValue(:final value) => PropertyState.calculating(
        oldValue: value,
      ),
      ErrorPropertyValue(:final error) => PropertyState.error(errorType: error),
    };
  }
}
