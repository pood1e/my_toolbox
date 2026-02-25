import 'package:flutter/material.dart';

import '../../ui/property_common_ui.dart';
import 'text_meta.dart';

class DescriptionMeta extends TextMeta with PropertyUiMeta {
  @override
  String get metaId => '_description';

  @override
  IconData get icon => Icons.description;

  @override
  String get name => '描述';

  @override
  TextConfig? get defaultConfig => const TextConfig(text: '');
}
