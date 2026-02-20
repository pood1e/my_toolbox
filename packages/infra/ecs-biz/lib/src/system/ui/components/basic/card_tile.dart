import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../component_widget.dart';

part 'card_tile.freezed.dart';

@freezed
abstract class CardTileConfig with _$CardTileConfig {
  const factory CardTileConfig({
    Widget? leading,
    Widget? title,
    Widget? trail,
    VoidCallback? onTap,
  }) = _CardTileConfig;
}

class CardTileComponent implements ComponentWidget {
  @override
  String get id => 'card_tile';

  @override
  WidgetType get type => WidgetType.basic;

  @override
  ComponentBuilder get builder =>
      (config) => CardTileWidget(config: config);
}

class CardTileWidget extends StatelessWidget {
  final CardTileConfig _config;

  const CardTileWidget({super.key, required CardTileConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: _config.onTap,
      leading: _config.leading,
      title: _config.title,
      trailing: _config.trail,
    ),
  );
}
