import '../../domain/compute_engine.dart';
import '../value_types/role_rule_data_type.dart';
import '../value_types/role_rules_data_type.dart';

class RoleRuleAggregator implements Aggregator<RoleRule, void, RoleRules> {
  @override
  void fromDb(value) {}

  @override
  String get id => 'agg_role_rules';

  @override
  String get sTypeId => 'role_rule';

  @override
  String get tTypeId => 'role_rules';

  @override
  toDb(void value) => null;

  @override
  String? validate(void config) => null;

  @override
  Future<RoleRules> aggregate(Map<String, RoleRule> sMap, void config) async =>
      RoleRules(typeMap: sMap);
}
