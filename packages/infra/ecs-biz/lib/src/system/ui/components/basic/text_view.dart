import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../component_widget.dart';

part 'text_view.freezed.dart';

@freezed
abstract class TextViewConfig with _$TextViewConfig {
  const factory TextViewConfig({required String text}) = _TextViewConfig;
}

class TextViewComponent implements ComponentWidget {
  @override
  String get id => 'text_input';

  @override
  WidgetType get type => WidgetType.basic;

  @override
  ComponentBuilder get builder =>
      (_, _, config) => TextViewWidget(config: config);
}

class TextViewWidget extends StatelessWidget {
  final TextViewConfig _config;

  const TextViewWidget({super.key, required TextViewConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context) => Text(_config.text);
}
