import 'package:app_core/di.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../../../domain/compute_engine.dart';
import '../../../domain/config_spec.dart';
import '../../../domain/property_config.dart';
import '../../../registry/config_spec_registry.dart';

class StaticSourceAddIcon extends ConsumerWidget {
  final String _specId;
  final void Function(String, ProcessorComponent) _createDefault;

  const StaticSourceAddIcon({
    super.key,
    required String specId,
    required void Function(String, ProcessorComponent) createDefault,
  }) : _specId = specId,
       _createDefault = createDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    onPressed: () {
      final specDescriptor = ref.read(configSpecDescriptorProvider(_specId));
      dynamic defaultValue;
      Processor component;
      if (specDescriptor is HybridConfigSpecDescriptor) {
        defaultValue = specDescriptor
            .processorSpecs[specDescriptor.defaultProcessor]!
            .createDefault();
        component =
            specDescriptor.processorMap[specDescriptor.defaultProcessor]!;
      } else if (specDescriptor is MultiStaticConfigSpecDescriptor) {
        defaultValue = specDescriptor
            .processorSpecs[specDescriptor.defaultProcessor]!
            .createDefault();
        component =
            specDescriptor.processorMap[specDescriptor.defaultProcessor]!;
      } else {
        throw UnimplementedError();
      }
      _createDefault(
        nanoid(10),
        ProcessorComponent(component: component, raw: defaultValue),
      );
    },
    icon: const Icon(Icons.add),
  );
}
