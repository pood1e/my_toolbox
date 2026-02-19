import 'package:app_core/logger.dart';

import '../../domain/compute_engine.dart';
import '../value_types/role_rule_data_type.dart';
import '../value_types/role_rules_data_type.dart';

class RoleRuleAggregator extends Aggregator<void, RoleRules> {
  @override
  void fromDb(value) {}

  @override
  String get id => 'agg_role_rules';

  @override
  String get tTypeId => 'role_rules';

  @override
  toDb(void value) => null;

  @override
  Future<RoleRules> aggregate(Map<String, dynamic> sMap, void config) async {
    final rules = <RoleRule>[];
    String? name;
    sMap.forEach((k, v) {
      if (k == 'name') name = v as String;
      if (v is RoleRule) rules.add(v);
    });
    if (name == null) {
      logger.w('role need name but absent');
      throw AggregatorException();
    }
    return RoleRules(name: name!, rules: rules);
  }
}
