import 'package:drift/drift.dart';

import '../data/node_database.dart';
import '../domain/data_type.dart';
import '../domain/property.dart';
import '../domain/stored_value.dart';
import '../ui/state/property_state.dart';

extension PropertiesCompanions on PropertiesCompanion {
  static PropertiesCompanion errorCompanion(ValueError valueError) =>
      clearValues().copyWith(
        valueStatus: const Value(ValueStatus.error),
        errorType: Value(valueError),
      );

  static PropertiesCompanion clearValues() => const PropertiesCompanion(
    valBool: Value(null),
    valInt: Value(null),
    valJson: Value(null),
    valReal: Value(null),
    valText: Value(null),
    valStr: Value(null),
  );

  static PropertiesCompanion keyed(PropertyKey key) =>
      PropertiesCompanion(nodeId: Value(key.nodeId), defId: Value(key.defId));

  PropertiesCompanion copyFrom(PropertiesCompanion other) =>
      PropertiesCompanion(
        nodeId: other.nodeId.present ? other.nodeId : nodeId,
        defId: other.defId.present ? other.defId : defId,
        valBool: other.valBool.present ? other.valBool : valBool,
        valInt: other.valInt.present ? other.valInt : valInt,
        valReal: other.valReal.present ? other.valReal : valReal,
        valText: other.valText.present ? other.valText : valText,
        valJson: other.valJson.present ? other.valJson : valJson,
        valStr: other.valJson.present ? other.valStr : valStr,
        valueStatus: other.valueStatus.present
            ? other.valueStatus
            : valueStatus,
        errorType: other.errorType.present ? other.errorType : errorType,
      );
}

extension PropertyDomainToCompanion on Property {
  PropertiesCompanion toCompanion() {
    final baseCompanion = PropertiesCompanions.keyed(key);

    if (value is ErrorStoredValue) {
      return baseCompanion.copyFrom(
        PropertiesCompanions.errorCompanion((value as ErrorStoredValue).error),
      );
    }

    ValueStatus status;
    StorageType storageType;
    dynamic rawValue;
    if (value is NormalStoredValue) {
      storageType = (value as NormalStoredValue).storageType;
      rawValue = (value as NormalStoredValue).value;
      status = ValueStatus.normal;
    } else {
      storageType = (value as DirtyStoredValue).storageType;
      rawValue = (value as DirtyStoredValue).value;
      status = ValueStatus.dirty;
    }

    // 添加状态信息
    final statusCompanion = baseCompanion.copyWith(
      valueStatus: Value(status),
      errorType: const Value(null),
    );

    // 根据存储类型设置对应的值字段
    return switch (storageType) {
      StorageType.bool => statusCompanion.copyWith(valBool: Value(rawValue)),
      StorageType.int => statusCompanion.copyWith(valInt: Value(rawValue)),
      StorageType.real => statusCompanion.copyWith(valReal: Value(rawValue)),
      StorageType.text => statusCompanion.copyWith(valText: Value(rawValue)),
      StorageType.json => statusCompanion.copyWith(valJson: Value(rawValue)),
      StorageType.str => statusCompanion.copyWith(valStr: Value(rawValue)),
    };
  }
}

extension PropertyEntityToDomain on PropertyEntity {
  Property toDomain(StorageType type) {
    // 构建 key
    final key = PropertyKey(nodeId: nodeId, defId: defId);
    if (valueStatus == ValueStatus.error) {
      return Property(
        key: key,
        value: StoredValue.error(error: errorType!),
      );
    }

    // 根据类型获取对应的值
    final rawValue = switch (type) {
      StorageType.bool => valBool,
      StorageType.int => valInt,
      StorageType.real => valReal,
      StorageType.text => valText,
      StorageType.json => valJson,
      StorageType.str => valStr,
    };

    return Property(
      key: key,
      value: switch (valueStatus) {
        ValueStatus.normal => StoredValue.normal(
          value: rawValue,
          storageType: type,
        ),
        ValueStatus.dirty => StoredValue.dirty(
          value: rawValue,
          storageType: type,
        ),
        _ => throw Exception(),
      },
    );
  }
}

extension PropertyDomainToState on Property? {
  PropertyState<T> toState<T>(DataTypeDefinition<T> converter) {
    if (this == null) {
      return PropertyState.uninitialized();
    }
    return switch (this!.value) {
      ErrorStoredValue(:final error) => PropertyState.error(errorType: error),

      NormalStoredValue(:final value) => PropertyState.idle(
        value: converter.fromDb(value) as T,
      ),
      DirtyStoredValue(:final value) => PropertyState.calculating(
        oldValue: converter.fromDb(value),
      ),
    };
  }
}
