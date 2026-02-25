import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../role/role_service.dart';
import '../../component_widget.dart';

class ShowRolePicker implements ComponentAction<Set<String>, String> {
  const ShowRolePicker();

  @override
  Future<String?> func(
    BuildContext context,
    WidgetRef ref,
    Set<String> config,
  ) async {
    final srv = ref.read(roleServiceProvider);
    final availableRoles = srv
        .getAllRoles()
        .where((role) => !config.contains(role.id))
        .toList();
    return await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacings.card),
          child: SizedBox(
            width: 400,
            child: Wrap(
              spacing: AppSpacings.s,
              children: availableRoles
                  .map(
                    (role) => FilledButton(
                      child: Text(role.name),
                      onPressed: () {
                        Navigator.of(context).pop(role.id);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
