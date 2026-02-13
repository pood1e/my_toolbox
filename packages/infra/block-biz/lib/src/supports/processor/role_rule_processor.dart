import 'package:app_core/di.dart';

import '../../domain/compute_engine.dart';
import '../../registry/property_descriptor_registry.dart';
import '../value_types/role_rule_data_type.dart';

class RoleRuleProcessor extends Processor<RoleRule, RoleRule> {
  final Ref _ref;

  RoleRuleProcessor({required Ref ref}) : _ref = ref;

  @override
  String? validate(RoleRule config) {
    if (_ref.read(propertyDescriptorProvider(config.propertyId)) == null) {
      return 'property not found';
    }
    return null;
  }

  @override
  RoleRule fromDb(value) => RoleRule.fromJson(value);

  @override
  String get id => 'role_rule';

  @override
  Future<RoleRule> process(RoleRule config) async => config;

  @override
  toDb(RoleRule value) => value.toJson();

  @override
  String get typeId => 'role_rule';
}
