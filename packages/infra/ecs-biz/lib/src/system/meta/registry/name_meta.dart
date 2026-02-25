import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../ui/property_common_ui.dart';
import 'text_meta.dart';

class NameMeta extends TextMeta with PropertyUiMeta {
  @override
  String get metaId => '_name';

  @override
  IconData get icon => Symbols.id_card;

  @override
  String get name => '名称';

  @override
  TextConfig? get defaultConfig => const TextConfig(text: 'unnamed');
}
