import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../../domain/config_spec.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../supports/config_spec_registry.dart';
import 'spec_renderer.dart';

class MultiStaticSpecRenderer extends ContentSpecRendererDefinition {
  final Map<String, String> proceesorRendererMap;
  final double maxHeight;
  final IconData? leadingIcon;

  MultiStaticSpecRenderer({
    required super.specId,
    required super.icon,
    required this.proceesorRendererMap,
    this.maxHeight = 400,
    this.leadingIcon,
  });

  @override
  List<Widget> extraActions({
    required PropertyConfigBody draft,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required VoidCallback onSubmit,
  }) => [
    StaticSourceAddIcon(
      specId: specId,
      createDefault: (component) {
        draft as MultiStaticPropertyConfig;
        onValueChanged(
          draft.copyWith(
            processorMap: {...draft.processorMap, nanoid(10): component},
          ),
        );
        onSubmit();
      },
    ),
  ];

  @override
  Widget build({
    required ContentSpecRenderer specRenderer,
    required PropertyKey currentKey,
    required String currentSpec,
    required PropertyConfigBody draft,
    required ValueChanged<PropertyConfigBody> onValueChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
  }) {
    draft as MultiStaticPropertyConfig;
    return StaticSourcesArea(
      leadingIcon: leadingIcon,
      config: draft,
      builder: (mapKey) {
        final component = draft.processorMap[mapKey]!;
        final renderer =
            specRenderer.proceesorRendererMap[component.component.id]!;
        return renderer.build(
          component.raw,
          (data) {
            onValueChanged(
              draft.copyWith(
                processorMap: {
                  ...draft.processorMap,
                  mapKey: component.copyWith(raw: data),
                },
              ),
            );
            onSubmit();
          },
          onFocusChanged,
          onSubmit,
          onCancel,
        );
      },
      onDelete: (mapKey) async {
        onValueChanged(
          draft.copyWith(processorMap: {...draft.processorMap}..remove(mapKey)),
        );
        onSubmit();
      },
      maxHeight: maxHeight,
    );
  }
}

class StaticSourceAddIcon extends ConsumerWidget {
  final String _specId;
  final void Function(ProcessorComponent) _createDefault;

  const StaticSourceAddIcon({
    super.key,
    required String specId,
    required void Function(ProcessorComponent) createDefault,
  }) : _specId = specId,
       _createDefault = createDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    onPressed: () {
      final specDescriptor =
          ref.read(configSpecDescriptorProvider(_specId))
              as MultiStaticConfigSpecDescriptor;
      final defaultValue = specDescriptor
          .processorSpecs[specDescriptor.defaultProcessor]!
          .createDefault();
      _createDefault(
        ProcessorComponent(
          component:
              specDescriptor.processorMap[specDescriptor.defaultProcessor]!,
          raw: defaultValue,
        ),
      );
    },
    icon: const Icon(Icons.add),
  );
}

class StaticSourcesArea extends StatelessWidget {
  final MultiStaticPropertyConfig _config;
  final Widget Function(String) _builder;
  final IconData? _leadingIcon;

  final void Function(String) _onDelete;
  final double _maxHeight;

  const StaticSourcesArea({
    super.key,
    required MultiStaticPropertyConfig config,
    required Widget Function(String) builder,
    IconData? leadingIcon,
    required void Function(String) onDelete,
    required double maxHeight,
  }) : _config = config,
       _builder = builder,
       _leadingIcon = leadingIcon,
       _onDelete = onDelete,
       _maxHeight = maxHeight;

  @override
  Widget build(BuildContext context) {
    final keys = _config.processorMap.keys.toList();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: _maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: keys.length,
        itemBuilder: (_, index) {
          final key = keys[index];
          return StaticSourceTile(
            key: ValueKey(key),
            leadingIcon: _leadingIcon,
            builder: () => _builder(key),
            onDelete: () {
              _onDelete(key);
            },
          );
        },
      ),
    );
  }
}

class StaticSourceTile extends StatelessWidget {
  final VoidCallback _onDelete;
  final Widget Function() _builder;
  final IconData? _leadingIcon;

  const StaticSourceTile({
    super.key,
    required VoidCallback onDelete,
    required Widget Function() builder,
    IconData? leadingIcon,
  }) : _onDelete = onDelete,
       _builder = builder,
       _leadingIcon = leadingIcon;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: _leadingIcon != null
        ? Icon(_leadingIcon, size: AppSizes.iconSmall)
        : null,
    title: _builder(),
    trailing: IconButton(onPressed: _onDelete, icon: const Icon(Icons.remove)),
  );
}
