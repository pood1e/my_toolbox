import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../component_widget.dart';

part 'text_input.freezed.dart';

@freezed
abstract class TextInputConfig with _$TextInputConfig {
  const factory TextInputConfig({
    required String initialText,
    required ValueChanged<String> onChanged,
  }) = _TextInputConfig;
}

class TextInputComponent implements ComponentWidget {
  @override
  String get id => 'text_input';

  @override
  WidgetType get type => WidgetType.basic;

  @override
  ComponentBuilder get builder =>
      (_, _, config) => TextInputWidget(config: config);
}

class TextInputWidget extends StatelessWidget {
  final TextInputConfig _config;

  const TextInputWidget({super.key, required TextInputConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: _config.initialText,
    onChanged: _config.onChanged,
  );
}
