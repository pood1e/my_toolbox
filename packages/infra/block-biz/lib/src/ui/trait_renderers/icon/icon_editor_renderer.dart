import 'package:flutter/material.dart';

import '../../../domain/shared.dart';
import '../../trait_renderer.dart';
import 'icon_editor.dart';

class IconEditorRenderer implements TraitRenderer {
  @override
  String get id => 'icon_editor';

  @override
  TraitType get traitType => TraitType.icon;

  @override
  Widget render(String traitId) => IconEditor(traitId: traitId);
}
