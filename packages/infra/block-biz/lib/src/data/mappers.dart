// lib/data/mappers/entity_mappers.dart
import 'package:drift/drift.dart';

import '../models/models.dart';
import 'node_database.dart';

// --- Node Mapper ---
extension NodeEntityToDomain on NodeEntity {
  Node toDomain() => Node(id: id, isValid: isValid);
}

extension NodeDomainToCompanion on Node {
  NodesCompanion toCompanion() =>
      NodesCompanion(id: Value(id), isValid: Value(isValid));
}

// --- Trait Mapper ---
extension TraitEntityToDomain on TraitEntity {
  Trait toDomain() => Trait(
    id: id,
    nodeId: nodeId,
    traitType: traitType, // 枚举自动匹配
    isValid: isValid,
  );
}

// --- Field Mapper ---
extension FieldEntityToDomain on FieldEntity {
  Field toDomain() {
    return Field(
      id: id,
      traitId: traitId,
      traitKey: traitKey,
      config: config ?? {},
      // 处理 null
      data: data,
      valueType: valueType,
      collectionType: collectionType,
      hasRef: hasRef,
      cacheable: cacheable,
      isValid: isValid,
      traitType: traitType,
    );
  }
}

// --- FieldRef Mapper ---
extension FieldRefEntityToDomain on FieldRefEntity {
  FieldRef toDomain() =>
      FieldRef(src: src, dst: dst, rank: rank ?? 0, fieldKey: fieldKey);
}

// --- Trait ---
extension TraitDomainToCompanion on Trait {
  /// 将 Trait Domain 对象转换为用于写入数据库的 TraitsCompanion
  TraitsCompanion toCompanion() {
    return TraitsCompanion(
      id: Value(id),
      nodeId: Value(nodeId),
      roleId: Value(roleId),
      roleLevel: Value(roleLevel),
      traitType: Value(traitType),
      isValid: Value(isValid),
    );
  }
}

// --- Field ---
extension FieldDomainToCompanion on Field {
  /// 将 Field Domain 对象转换为用于写入数据库的 FieldsCompanion
  FieldsCompanion toCompanion() {
    return FieldsCompanion(
      id: Value(id),
      traitId: Value(traitId),
      traitKey: Value(traitKey),
      // TypeConverter 会自动将 Map<String, dynamic> 转换为 JSON 字符串
      config: Value(config),
      data: Value(data),
      valueType: Value(valueType),
      collectionType: Value(collectionType),
      hasRef: Value(hasRef),
      cacheable: Value(cacheable),
      isValid: Value(isValid),
      // 关键：冗余字段 traitType 在这里设置
      traitType: Value(traitType),
    );
  }
}

// --- FieldRef ---
extension FieldRefDomainToCompanion on FieldRef {
  /// 将 FieldRef Domain 对象转换为用于写入数据库的 FieldRefsCompanion
  FieldRefsCompanion toCompanion() {
    return FieldRefsCompanion(
      src: Value(src),
      dst: Value(dst),
      rank: Value(rank),
      fieldKey: Value(fieldKey),
    );
  }
}
