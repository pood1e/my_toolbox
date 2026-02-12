import 'dart:convert';

import 'package:app_core/object.dart';

import '../../domain/data_type.dart';
import '../../domain/stored_value.dart';
import 'role_rule_data_type.dart';

part 'role_rules_data_type.freezed.dart';
part 'role_rules_data_type.g.dart';

@freezed
abstract class RoleRules with _$RoleRules {
  const factory RoleRules({required Map<String, RoleRule> typeMap}) =
      _RoleRule;

  factory RoleRules.fromJson(Map<String, dynamic> json) =>
      _$RoleRulesFromJson(json);
}

class RoleRulesDataType implements DataTypeDefinition<RoleRules> {
  @override
  RoleRules? fromDb(value) {
    if (value == null) return null;
    final Map<String, dynamic> json = jsonDecode(value);
    return RoleRules.fromJson(json);
  }

  @override
  String get id => 'role_rules';

  @override
  StorageType get storageType => StorageType.json;

  @override
  toDb(RoleRules value) => jsonEncode(value.toJson());
}
