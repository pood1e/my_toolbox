// 1. 特征类型：决定一个特征的业务含义
import 'package:app_core/object.dart';

import '../domain/shared.dart';

part 'models.freezed.dart';

@freezed
abstract class Node with _$Node {
  const factory Node({required String id, @Default(false) bool isValid}) =
      _Node;
}

@freezed
abstract class Trait with _$Trait {
  const factory Trait({
    required String id,
    String? nodeId,
    String? roleId,
    RoleLevel? roleLevel,
    required TraitType traitType, // 使用枚举
    @Default(true) bool isValid,
  }) = _Trait;
}

@freezed
abstract class Field with _$Field {
  const factory Field({
    required String id,
    required String traitId,
    String? traitKey,

    // Config 和 Data 在 Domain 层直接作为 Map 处理
    @Default({}) Map<String, dynamic> config,
    dynamic data,

    required ValueType valueType,
    required TraitType traitType, // 使用枚举
    @Default(CollectionType.none) CollectionType collectionType,

    @Default(false) bool hasRef,
    @Default(false) bool cacheable,
    @Default(true) bool isValid,
  }) = _Field;
}

@freezed
abstract class FieldRef with _$FieldRef {
  const factory FieldRef({
    required String src,
    required String dst,
    int? rank,
    String? fieldKey, // 之前新增的字段
  }) = _FieldRef;
}
