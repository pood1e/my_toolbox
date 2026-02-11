import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/material.dart';

import '../../../../domain/property.dart';
import '../../../../domain/stored_value.dart';
import '../../../../mappers/property_mapper.dart';
import '../../../../supports/property_descriptor_registry.dart';
import '../../../state/property_state.dart';
import '../node_editor_controller.dart';

class ReadContainer extends ConsumerWidget {
  final PropertyKey propertyKey;
  final Widget Function(PropertyState state) builder;

  const ReadContainer({super.key, required this.propertyKey, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取 Descriptor 用于类型转换
    final descriptor = ref.watch(propertyDescriptorProvider(propertyKey.defId));

    // 监听实时属性值
    // 这里我们需要从 repo 获取 Raw Value 并转化为 PropertyState
    // 为了简化，这里临时构造一个 Provider 或者复用现有的逻辑
    // 假设有一个 provider 可以提供 Property? stream
    final propertyAsync = ref.watch(watchPropertyProvider(propertyKey));

    return propertyAsync.whenUI(
      data: (property) {
        final state = property.toState(descriptor.dateType.definition);
        return builder(state);
      }
    );
  }
}
