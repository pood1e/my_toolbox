import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../component_widget.dart';

part 'reuse_widget.freezed.dart';

@freezed
abstract class ReuseComponentConfig with _$ReuseComponentConfig {
  const factory ReuseComponentConfig({
    required String componentId,
    required WidgetType type,
    required dynamic config,
  }) = _ReuseComponentConfig;
}

class ReuseComponent implements ComponentWidget {
  @override
  ComponentBuilder get builder =>
      (config) => ReuseWidget(config: config);

  @override
  String get id => 'reuse_widget';

  @override
  WidgetType get type => WidgetType.basic;
}

class ReuseWidget extends ConsumerWidget {
  final ReuseComponentConfig _config;

  const ReuseWidget({super.key, required ReuseComponentConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builder = ref
        .read(componentServiceProvider)
        .getBuilder(_config.type, _config.componentId)!;
    return builder(_config.config);
  }

  static Widget? orNull(ReuseComponentConfig? config) =>
      config != null ? ReuseWidget(config: config) : null;
}
