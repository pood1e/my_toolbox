import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../domain/property.dart';
import '../../../../supports/property_def_registry.dart';
import '../../../common_property_controller.dart';
import '../../../state/property_state.dart';
import '../node_editor_controller.dart';
import '../property_edit_support.dart';
import '../property_editor_registry.dart';

class NameEditor extends EditorDescriptor<String, String> {
  @override
  String get propertyId => '_name';

  @override
  String get name => 'name';

  @override
  IconData get icon => Symbols.id_card;

  @override
  String get defaultConfig => 'unnamed';

  @override
  Widget Function(PropertyKey) get configWidgetBuilder =>
      (key) => _NameEditorWidget(propertyKey: key);

  @override
  Widget Function(PropertyKey)? get valueWidgetBuilder =>
      (key) => _NameViewerWidget(propertyKey: key);
}

class _NameViewerWidget extends ConsumerWidget {
  final PropertyKey _propertyKey;

  const _NameViewerWidget({required PropertyKey propertyKey})
    : _propertyKey = propertyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.read(editorDescriptorProvider(_propertyKey.defId));
    return ref
        .watch(watchPropertyProvider(_propertyKey))
        .whenUI(
          data: (state) => ListTile(
            title: Text(state.getValue() ?? descriptor.defaultConfig),
          ),
        );
  }
}

class _NameEditorWidget extends ConsumerStatefulWidget {
  final PropertyKey propertyKey;

  const _NameEditorWidget({required this.propertyKey});

  @override
  ConsumerState<_NameEditorWidget> createState() => _NameEditorWidgetState();
}

class _NameEditorWidgetState extends ConsumerState<_NameEditorWidget> {
  late final TextEditingController _controller;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerAsync = ref.watch(
      commonConfigControllerProvider(widget.propertyKey),
    );

    final descriptor = ref.read(
      propertyDescriptorProvider(widget.propertyKey.defId),
    );

    return controllerAsync.whenUI(
      data: (config) {
        final currentValue =
            descriptor.typeDescriptor.configConverter.decode(config.configs)
                as String;

        if (!_isInitialized) {
          _controller.text = currentValue;
          _isInitialized = true;
        }

        return Card(
          child: ListTile(
            title: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter name',
                border: InputBorder.none,
              ),
            ),
            trailing:
                _controller.text.isNotEmpty && _controller.text != currentValue
                ? IconButton(
                    onPressed: () async {
                      final notifier = ref.read(
                        commonConfigControllerProvider(
                          widget.propertyKey,
                        ).notifier,
                      );
                      await notifier.fullUpdate(_controller.text);
                      ref
                          .read(
                            nodeEditorModeControllerProvider(
                              widget.propertyKey,
                            ).notifier,
                          )
                          .toggle();
                    },
                    icon: const Icon(Icons.check),
                  )
                : null,
          ),
        );
      },
    );
  }
}
