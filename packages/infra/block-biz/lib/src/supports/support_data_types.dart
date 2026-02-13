import 'package:app_core/di.dart';

import '../domain/data_type.dart';
import 'value_types/icon_data_type.dart';
import 'value_types/role_rule_data_type.dart';
import 'value_types/role_rules_data_type.dart';
import 'value_types/text_data_type.dart';

part 'support_data_types.g.dart';

@Riverpod(keepAlive: true)
List<DataTypeDefinition> dataTypeDefinitions(Ref ref) => [
  TextDataType(),
  IconDataType(),
  RoleRuleDataType(),
  RoleRulesDataType(),
];
