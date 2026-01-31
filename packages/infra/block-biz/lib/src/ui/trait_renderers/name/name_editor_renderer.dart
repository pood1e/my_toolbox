import 'package:flutter/material.dart';

import '../../../domain/shared.dart';
import '../../trait_renderer.dart';
import 'name_editor.dart';

class NameEditorRenderer implements TraitRenderer {
  @override
  String get id => 'name_editor';

  @override
  TraitType get traitType => TraitType.name;

  @override
  Widget render(String traitId) => NameEditor(traitId: traitId);
}
