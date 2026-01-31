import 'package:app_core/object.dart';

part 'shared.freezed.dart';

enum RoleLevel { mandatory, blueprint, suggested }

enum TraitType { name, description, icon }

enum ValueType { string, double, int, date, timestamp, json, field, trait }

enum CollectionType { none, list, set, map }

@freezed
abstract class FieldDefinition with _$FieldDefinition {
  const factory FieldDefinition({
    String? key, // 数据库中的 traitKey
    required ValueType valueType,
    Map<String, dynamic>? config,
    Map<String, dynamic>? defaultValue,
  }) = _FieldDefinition;
}

