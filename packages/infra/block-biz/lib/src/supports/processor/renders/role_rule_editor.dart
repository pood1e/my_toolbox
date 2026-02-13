import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../ui/component_renderer.dart';
import '../../support_properties.dart';
import '../../value_types/role_rule_data_type.dart';

class RoleRuleRenderer implements ContentRenderer {
  @override
  Widget build(
    config,
    ValueChanged<dynamic> onValueChanged,
    ValueChanged<bool> onFocusChanged,
    VoidCallback onSubmit,
    VoidCallback onCancel,
  ) => RoleRuleEditor(
    rule: config,
    onChanged: onValueChanged,
    onSumbit: onSubmit,
  );

  @override
  String get id => 'role_rule_editor';
}

class RoleRuleEditor extends ConsumerWidget {
  final RoleRule _rule;
  final ValueChanged<RoleRule> _onChanged;
  final VoidCallback _onSumbit;

  const RoleRuleEditor({
    super.key,
    required RoleRule rule,
    required ValueChanged<RoleRule> onChanged,
    required VoidCallback onSumbit,
  }) : _rule = rule,
       _onChanged = onChanged,
       _onSumbit = onSumbit;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    direction: Axis.horizontal,
    spacing: AppSpacings.s,
    runSpacing: AppSpacings.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      // property selector
      DropdownMenu(
        label: const Text('property'),
        // textStyle: Theme.of(context).textTheme.bodySmall,
        showTrailingIcon: false,
        initialSelection: _rule.propertyId,
        dropdownMenuEntries: ref
            .read(propertyDefinitionsProvider)
            .where((def) => def.canBeRule)
            .map(
              (def) => DropdownMenuEntry(
                value: def.propertyId,
                label: def.propertyId,
              ),
            )
            .toList(),
        onSelected: (propertyId) {
          if (propertyId != null) {
            _onChanged(_rule.copyWith(propertyId: propertyId));
            _onSumbit();
          }
        },
      ),
      // level
      CompactDropdown<RoleRuleType>(
        value: _rule.type,
        valueToLabel: (t) => t.name,
        items: RoleRuleType.values,
        onChanged: (type) {
          _onChanged(_rule.copyWith(type: type));
          _onSumbit();
        },
      ),
    ],
  );
}
