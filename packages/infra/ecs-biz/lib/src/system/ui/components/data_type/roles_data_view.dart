import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../role/role_service.dart';
import '../../component_widget.dart';

class RolesDataView extends DataTypeWidget {
  @override
  ComponentBuilder get builder =>
      (roles) => RolesDataWidget(roleMap: roles);

  @override
  String get dataTypeId => 'roles';

  @override
  String get id => 'roles_view';

  @override
  bool get isDefault => true;
}

class RolesDataWidget extends ConsumerWidget {
  final Map<String, bool> _roleMap;

  const RolesDataWidget({super.key, required Map<String, bool> roleMap})
    : _roleMap = roleMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final srv = ref.read(roleServiceProvider);
    return Wrap(
      spacing: AppSpacings.s,
      children: _roleMap.entries.map((entry) {
        final role = srv.getById(entry.key)!;
        return Chip(label: Text(role.name));
      }).toList(),
    );
  }
}
