import 'package:app_core/object.dart';
import 'package:flutter/cupertino.dart';

import '../../component_widget.dart';
import 'reuse_widget.dart';

part 'list_widget.freezed.dart';

@freezed
abstract class ListComponentConfig with _$ListComponentConfig {
  const factory ListComponentConfig({
    @Default([]) List<ReuseComponentConfig> configs,
  }) = _ListComponentConfig;
}

class ListComponent implements ComponentWidget {
  @override
  String get id => 'list_widget';

  @override
  WidgetType get type => WidgetType.basic;

  @override
  ComponentBuilder get builder =>
      (config) => ListWidget(config: config);
}

class ListWidget extends StatelessWidget {
  final ListComponentConfig _config;

  const ListWidget({super.key, required ListComponentConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: _config.configs.length,
    itemBuilder: (_, i) => ReuseWidget(config: _config.configs[i]),
  );
}
