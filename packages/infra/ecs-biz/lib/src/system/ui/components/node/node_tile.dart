import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:app_core/route.dart';
import 'package:common_ui/component.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../../meta/property_meta_service.dart';
import '../../../value/value_service.dart';
import '../../component_widget.dart';
import '../basic/card_tile.dart';

part 'node_tile.freezed.dart';
part 'node_tile.g.dart';

@freezed
abstract class NodeTileConfig with _$NodeTileConfig {
  const factory NodeTileConfig({required String nodeId}) = _NodeTileConfig;
}

@freezed
abstract class NodeBasicInfo with _$NodeBasicInfo {
  const factory NodeBasicInfo({
    @Default('unnamed') String name,
    @Default(Icons.question_mark) IconData icon,
  }) = _NodeBasicInfo;
}

class NodeTileComponent implements ComponentWidget {
  @override
  String get id => 'node_tile';

  @override
  WidgetType get type => WidgetType.node;

  @override
  ComponentBuilder get builder =>
      (cfg) => NodeTileWidget(config: cfg);
}

@riverpod
Stream<NodeBasicInfo> watchNodeBasicInfo(Ref ref, String nodeId) async* {
  final service = await ref.watch(valueServiceProvider.future);
  yield* service
      .watchValues({
        PropertyId(nodeId: nodeId, metaId: '_name'),
        PropertyId(nodeId: nodeId, metaId: '_icon'),
      })
      .map((result) {
        NodeBasicInfo info = const NodeBasicInfo();
        for (final val in result) {
          if (val.propertyId.metaId == '_name' && val.value != null) {
            info = info.copyWith(name: val.value);
          }
          if (val.propertyId.metaId == '_icon' && val.value != null) {
            info = info.copyWith(icon: val.value);
          }
        }
        return info;
      });
}

class NodeInfoChip extends ConsumerWidget {
  final String _nodeId;

  const NodeInfoChip({super.key, required String nodeId}) : _nodeId = nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(watchNodeBasicInfoProvider(_nodeId));
    return infoAsync.whenUI(
      data: (info) => Wrap(
        direction: Axis.horizontal,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppSpacings.s,
        spacing: AppSpacings.s,
        children: [Icon(info.icon), Text(info.name)],
      ),
    );
  }
}

class NodeTileWidget extends ConsumerWidget {
  final NodeTileConfig _config;

  const NodeTileWidget({super.key, required NodeTileConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CardTileWidget(
    config: CardTileConfig(
      title: NodeInfoChip(nodeId: _config.nodeId),
      onTap: () {
        context.push('/node/${_config.nodeId}');
      },
    ),
  );
}
