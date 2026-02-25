import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';
import '../../../value/value_service.dart';
import '../../component_widget.dart';
import '../../property_common_ui.dart';

part 'node_editor.freezed.dart';
part 'node_editor.g.dart';

@freezed
abstract class NodeEditorConfig with _$NodeEditorConfig {
  const factory NodeEditorConfig({required String nodeId}) = _NodeEditorConfig;
}

class NodeEditorComponent implements ComponentWidget {
  @override
  String get id => 'node_editor';

  @override
  WidgetType get type => WidgetType.node;

  @override
  ComponentBuilder get builder =>
      (cfg) => NodeEditorWidget(config: cfg);
}

@freezed
abstract class NodeEditorState with _$NodeEditorState {
  const factory NodeEditorState({String? name, required Set<String> metas}) =
      _NodeEditorState;
}

@riverpod
Future<String?> watchNodeNameVal(Ref ref, String nodeId) async {
  final val = await ref.watch(
    watchValueProvider(PropertyId(nodeId: nodeId, metaId: '_name')).future,
  );
  return val?.value;
}

@riverpod
class NodeEditorController extends _$NodeEditorController {
  @override
  Future<NodeEditorState> build(String nodeId) async {
    final metas = await ref.watch(watchMetasByNodeProvider(nodeId).future);
    final name = await ref.watch(watchNodeNameValProvider(nodeId).future);
    return NodeEditorState(name: name, metas: metas);
  }

  Future<void> addDefaultConfig(String metaId) async {
    final service = await ref.read(configServiceProvider.future);
    final meta = ref.read(propertyMetaServiceProvider).getById(metaId);

    await service.create(
      PropertyId(nodeId: nodeId, metaId: metaId),
      (meta as PropertyConfigMeta).defaultConfig,
    );
  }
}

@freezed
abstract class PropertyEditorConfig with _$PropertyEditorConfig {
  const factory PropertyEditorConfig({
    required String metaId,
    required String widgetId,
    dynamic config,
  }) = _PropertyEditorConfig;
}

final _supportMetas = [
  const PropertyEditorConfig(metaId: '_roles', widgetId: 'roles_editor'),
  const PropertyEditorConfig(metaId: '_name', widgetId: 'name_editor'),
  const PropertyEditorConfig(metaId: '_icon', widgetId: 'icon_editor'),
  const PropertyEditorConfig(metaId: '_description', widgetId: 'description_editor'),

];

class NodeEditorWidget extends ConsumerWidget {
  final NodeEditorConfig _config;

  const NodeEditorWidget({super.key, required NodeEditorConfig config})
    : _config = config;

  Widget? _buildFab(
    BuildContext context,
    WidgetRef ref,
    Set<String> existMetas,
  ) {
    final notifier = ref.read(
      nodeEditorControllerProvider(_config.nodeId).notifier,
    );
    final supportMetas = _supportMetas;
    // 1. 筛选可用属性
    final availableAppend = supportMetas
        .where((meta) => !existMetas.contains(meta.metaId))
        .toList();

    // 2. 这里的 buttons 是作为 ExpandableFab 的 children (子菜单项)
    // 子菜单项通常不显示在屏幕上，直到展开，所以给它们 heroTag: null 是对的，防止报错
    final fabChildren = availableAppend.map((property) {
      Widget? icon;
      Widget label;
      final meta = ref
          .read(propertyMetaServiceProvider)
          .getById(property.metaId);
      if (meta is PropertyUiMeta) {
        icon = Icon(meta.icon);
        label = Text(meta.name);
      } else {
        label = Text(property.metaId);
      }
      return FloatingActionButton.extended(
        icon: icon,
        heroTag: null, // 子按钮不需要 Hero
        label: label,
        onPressed: () {
          notifier.addDefaultConfig(property.metaId);
        },
      );
    }).toList();

    // 3. 逻辑分叉
    if (fabChildren.isNotEmpty) {
      // === 多按钮模式 (ExpandableFab) ===
      return ExpandableFab(
        distance: fabChildren.length * 50 + 50,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          heroTag: null,
          child: const Icon(Icons.add),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          heroTag: null, // 关闭按钮通常不需要 Tag
        ),
        overlayStyle: const ExpandableFabOverlayStyle(blur: 5.0),
        children: fabChildren,
      );
    } else {
      // 没有可添加的属性
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(nodeEditorControllerProvider(_config.nodeId));
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(stateAsync.value?.name ?? 'unnamed'),
      ),
      floatingActionButton: _buildFab(
        context,
        ref,
        stateAsync.value?.metas ?? <String>{},
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      body: stateAsync.whenUI(
        data: (state) {
          final supportMetas = _supportMetas
              .where((meta) => state.metas.contains(meta.metaId))
              .toList();
          return ListView.builder(
            itemBuilder: (_, index) {
              final meta = supportMetas[index];
              final builder = ref
                  .read(componentServiceProvider)
                  .getPropertyBuilder(meta.metaId, meta.widgetId)!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacings.l),
                child: builder(_config.nodeId, null),
              );
            },
            itemCount: supportMetas.length,
          );
        },
      ),
    );
  }
}
