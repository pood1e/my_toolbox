import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import '../../component_widget.dart';
import '../basic/card_tile.dart';
import '../basic/text_view.dart';
import '../property/name_view.dart';

part 'node_tile.freezed.dart';

@freezed
abstract class NodeTileConfig with _$NodeTileConfig {
  const factory NodeTileConfig({required String nodeId}) = _NodeTileConfig;
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

class NodeTileWidget extends ConsumerWidget {
  final NodeTileConfig _config;

  const NodeTileWidget({super.key, required NodeTileConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(watchNodeNameValProvider(_config.nodeId));
    return CardTileWidget(
      config: CardTileConfig(
        title: TextViewWidget(
          config: TextViewConfig(text: nameAsync.value ?? 'unnamed'),
        ),
        onTap: () {
          context.push('/node/${_config.nodeId}');
        },
      ),
    );
  }
}
