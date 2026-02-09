import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../../domain/property.dart';
import '../../../domain/property_config.dart';
import 'property_editor_controller.dart';
import 'property_editor_descriptor.dart';
import 'property_editor_registry.dart';
import 'property_editors/node_reference_editor.dart';
import 'property_editors/text_editor.dart';

// File: ui/node_renderers/node_editor/property_edit_tile.dart

class PropertyEditTile extends ConsumerWidget {
  final PropertyKey propertyKey;

  const PropertyEditTile({super.key, required this.propertyKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descriptor = ref.read(
      propertyEditorDescriptorProvider(propertyKey.defId),
    );
    final stateAsync = ref.watch(propertyEditorControllerProvider(propertyKey));

    return stateAsync.when(
      loading: () => const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Text('Error: $err'),
      data: (state) {
        final activeMode = state.activeMode;

        // 找到当前模式对应的 Spec
        final activeSpec = descriptor.supportedModes.firstWhere(
          (m) => m.mode == activeMode,
          orElse: () => descriptor.defaultMode,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              // 1. Header: 图标 + 名称 + 模式切换器
              _buildHeader(context, ref, descriptor, activeSpec),

              // 2. Body: 具体编辑器
              // 根据 draft 配置渲染
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildSpecificEditor(state.draft, activeSpec),
              ),

              // 3. Saving Indicator
              if (state.isSaving) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    PropertyEditorDescriptor descriptor,
    EditorModeSpec activeSpec,
  ) {
    final controller = ref.read(
      propertyEditorControllerProvider(propertyKey).notifier,
    );

    // 如果只有一个模式，隐藏下拉菜单
    final showModeSwitch = descriptor.supportedModes.length > 1;

    return ListTile(
      dense: true,
      leading: Icon(descriptor.icon, size: 20),
      title: Text(
        descriptor.name,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      trailing: showModeSwitch
          ? DropdownButton<EditorModeSpec>(
              value: activeSpec,
              isDense: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.more_vert, size: 18),
              items: descriptor.supportedModes.map((spec) => DropdownMenuItem(
                  value: spec,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(spec.icon, size: 16),
                      const SizedBox(width: 8),
                      Text(spec.label, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )).toList(),
              onChanged: (newSpec) {
                if (newSpec != null && newSpec != activeSpec) {
                  controller.switchMode(newSpec);
                }
              },
            )
          : null,
    );
  }

  /// 策略模式：分发到具体 Widget
  Widget _buildSpecificEditor(PropertyConfig config, EditorModeSpec spec) {
    // 这里使用 Pattern Matching 确保类型安全
    return config.map(
      singleStatic: (c) {
        if (spec is StaticModeSpec) {
          // 这里根据 processorId 决定显示哪个输入框
          // 实际项目中建议使用 Registry 查找，这里为了演示直接判断
          if (spec.processorId == 'direct_text') {
            return TextInputEditor(config: c, propertyKey: propertyKey);
          }
        }
        return const Text('Configuration mismatch');
      },
      singleRef: (c) =>
          NodeReferenceEditor(config: c, propertyKey: propertyKey),
      multiStatic: (_) => const Text('Multi-static editor not implemented'),
      multiRef: (_) => const Text('Multi-ref editor not implemented'),
      hybrid: (_) => const Text('Hybrid editor not implemented'),
    );
  }
}
