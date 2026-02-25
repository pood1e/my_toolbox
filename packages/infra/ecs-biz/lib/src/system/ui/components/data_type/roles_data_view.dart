import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../role/role_service.dart';
import '../../../value/data_types/roles_data_type.dart';
import '../../component_widget.dart';

class RolesDataView extends DataTypeWidget {
  @override
  ComponentBuilder get builder =>
      (status) => RolesDataWidget(status: status);

  @override
  String get dataTypeId => 'roles';

  @override
  String get id => 'roles_view';

  @override
  bool get isDefault => true;
}

class RolesDataWidget extends ConsumerWidget {
  final RolesStatus _status;

  const RolesDataWidget({super.key, required RolesStatus status})
    : _status = status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final srv = ref.read(roleRegistryProvider);
    final success = _status.status.where((status) => status.success).toList();
    final errors = _status.status.where((status) => !status.success).toList();
    return Column(
      children: [
        Wrap(
          spacing: AppSpacings.s,
          children: success.map((status) {
            final role = srv.getById(status.roleId)!;
            return Chip(
              label: Wrap(
                spacing: AppSpacings.s,
                runSpacing: AppSpacings.s,
                children: [Icon(role.icon), Text(role.name)],
              ),
            );
          }).toList(),
        ),
        ...errors.map(
          (status) => Wrap(
            spacing: AppSpacings.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text(srv.getById(status.roleId)!.name)),
              Text(status.reasons.first),
            ],
          ),
        ),
      ],
    );
  }
}
