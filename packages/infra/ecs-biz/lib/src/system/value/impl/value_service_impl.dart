import 'package:drift/drift.dart';

import '../../compute/compute_service.dart';
import '../../meta/property_meta_service.dart';
import '../../storage/ecs_database.dart';
import '../data/value_dao.dart';
import '../value_service.dart';

class ValueServiceImpl implements ValueService {
  final Map<String, DataType> _typeMap;
  final PropertyMetaService _metaService;
  final ValueDao _dao;

  ValueServiceImpl({
    required List<DataType> dataTypes,
    required PropertyMetaService metaService,
    required ValueDao dao,
  }) : _typeMap = {for (final dataType in dataTypes) dataType.id: dataType},
       _metaService = metaService,
       _dao = dao;

  @override
  Future<PropertyVal?> getValue(PropertyId propertyId) async {
    final meta = _metaService.getById(propertyId.metaId);
    if (meta == null) {
      throw Exception('Meta not found for metaId: ${propertyId.metaId}');
    }
    if (meta is! PropertyValueMeta) {
      return null;
    }

    // 1. 从数据库获取原始实体
    final entity = await _dao.getValue(propertyId);
    return _convertToPropertyVal(entity);
  }

  @override
  Future<void> update(PropertyId propertyId, PropertyVal val) async {
    final meta = _metaService.getById(propertyId.metaId);
    if (meta == null) {
      throw Exception('Meta not found for metaId: ${propertyId.metaId}');
    }
    if (meta is! PropertyValueMeta) {
      return;
    }

    var companion = PropertyValsCompanion(
      metaId: Value(propertyId.metaId),
      nodeId: Value(propertyId.nodeId),
      status: Value(val.status),
      extra: Value(val.extra),
      valBool: const Value(null),
      valInt: const Value(null),
      valReal: const Value(null),
      valText: const Value(null),
      valStr: const Value(null),
      valJson: const Value(null),
    );

    if (val.value != null) {
      dynamic dbValue = val.value;

      final dataType = _typeMap[meta.dataTypeId];
      if (dataType != null) {
        dbValue = dataType.toDb(val.value);
      }

      switch (meta.storageType) {
        case StorageType.bool:
          companion = companion.copyWith(valBool: Value(dbValue as bool));
          break;
        case StorageType.int:
          companion = companion.copyWith(valInt: Value(dbValue as int));
          break;
        case StorageType.real:
          companion = companion.copyWith(valReal: Value(dbValue as double));
          break;
        case StorageType.text:
          companion = companion.copyWith(valText: Value(dbValue as String));
          break;
        case StorageType.str:
          companion = companion.copyWith(valStr: Value(dbValue as String));
          break;
        case StorageType.json:
          companion = companion.copyWith(
            valJson: Value(dbValue as Map<String, dynamic>),
          );
          break;
      }
    }

    await _dao.setValue(companion);
  }

  @override
  Future<void> delete(PropertyId propertyId) async {
    await _dao.deleteValue(propertyId);
  }

  @override
  Future<void> markAsDirty(Set<PropertyId> propertyIds) async {
    await _dao.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _dao.propertyVals,
        propertyIds
            .map(
              (propertyId) => PropertyValsCompanion(
                nodeId: Value(propertyId.nodeId),
                metaId: Value(propertyId.metaId),
                status: const Value(ValueStatus.dirty),
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<void> markAsError(Map<PropertyId, ComputeError> errorMap) async {
    await _dao.batch((batch) {
      errorMap.forEach((k, v) {
        batch.update(
          _dao.propertyVals,
          PropertyValsCompanion(
            valBool: const Value(null),
            valStr: const Value(null),
            valText: const Value(null),
            valInt: const Value(null),
            valReal: const Value(null),
            valJson: const Value(null),
            extra: Value(v.name),
            status: const Value(ValueStatus.error),
          ),
          where: (t) => t.nodeId.equals(k.nodeId) & t.metaId.equals(k.metaId),
        );
      });
    });
  }

  @override
  Stream<List<PropertyVal>> watchValues(List<PropertyId> ids) => _dao
      .watchValuesList(ids)
      .map(
        (vals) =>
            vals.map(_convertToPropertyVal).whereType<PropertyVal>().toList(),
      );

  /// 提取的私有方法：将数据库实体转为运行时 PropertyVal
  PropertyVal? _convertToPropertyVal(PropertyValEntity? entity) {
    if (entity == null) return null;
    final meta = _metaService.getById(entity.metaId);
    if (meta is! PropertyValueMeta) {
      return null;
    }
    dynamic rawDbValue;
    switch (meta.storageType) {
      case StorageType.bool:
        rawDbValue = entity.valBool;
        break;
      case StorageType.int:
        rawDbValue = entity.valInt;
        break;
      case StorageType.real:
        rawDbValue = entity.valReal;
        break;
      case StorageType.text:
        rawDbValue = entity.valText;
        break;
      case StorageType.str:
        rawDbValue = entity.valStr;
        break;
      case StorageType.json:
        rawDbValue = entity.valJson;
        break;
    }

    // 2. 如果定义了 DataType，进行类型转换 (DB -> Runtime)
    dynamic runtimeValue = rawDbValue;
    if (rawDbValue != null) {
      final dataType = _typeMap[meta.dataTypeId]!;
      runtimeValue = dataType.fromDb(rawDbValue);
    }

    return PropertyVal(
      value: runtimeValue,
      status: entity.status,
      extra: entity.extra,
    );
  }
}
