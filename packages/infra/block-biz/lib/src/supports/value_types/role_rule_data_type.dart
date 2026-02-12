import 'package:app_core/object.dart';

import '../../domain/data_type.dart';
import '../../domain/stored_value.dart';

part 'role_rule_data_type.freezed.dart';
part 'role_rule_data_type.g.dart';

enum RoleRuleType { mandatory, blueprint, sugguested }

@freezed
abstract class RoleRule with _$RoleRule {
  const factory RoleRule({required RoleRuleType type}) = _RoleRule;

  factory RoleRule.fromJson(Map<String, dynamic> json) =>
      _$RoleRuleFromJson(json);
}

class RoleRuleDataType implements DataTypeDefinition<RoleRule> {
  @override
  RoleRule? fromDb(value) => RoleRule.fromJson(value);

  @override
  String get id => 'role_rule';

  @override
  StorageType get storageType => StorageType.json;

  @override
  toDb(RoleRule value) => value.toJson();
}
