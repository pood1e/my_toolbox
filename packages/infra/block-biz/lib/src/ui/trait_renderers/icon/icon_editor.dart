import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import 'icon_editor_controller.dart';

class IconEditor extends ConsumerWidget {
  final String traitId;

  const IconEditor({super.key, required this.traitId});

  Future<void> _pickAndSave(
    BuildContext context,
    WidgetRef ref,
    IconData? currentIcon,
  ) async {
    IconPickerIcon? result = await showIconPicker(
      context,
      configuration: SinglePickerConfiguration(
        iconPackModes: [
          IconPack.material,
          IconPack.fontAwesomeIcons,
          IconPack.cupertino,
          IconPack.lineAwesomeIcons,
        ],
      ),
    );

    if (result != null) {
      IconData pickedIcon = result.data;
      await ref
          .read(iconEditorControllerProvider(traitId).notifier)
          .updateIcon(pickedIcon);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(iconEditorControllerProvider(traitId));
    final statusColors = context.theme.extension<AppStatusColors>()!;

    return stateAsync.whenUI(
      data: (state) => Card(
        child: ListTile(
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.stars,
              color: state.isValid
                  ? statusColors.success
                  : Colors.grey,
            ),
          ),
          title: const Text('Icon'),
          trailing: Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: Icon(state.config),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _pickAndSave(context, ref, state.config),
        ),
      ),
    );
  }
}
