import 'package:app_core/di.dart';

import 'property_edit_support.dart';
import 'property_editors/icon_editor.dart';
import 'property_editors/name_editor.dart';

part 'property_editor_registry.g.dart';

@riverpod
List<EditorDescriptor> editorDescriptors(Ref ref) => [
  NameEditor(),
  IconEditor(),
];

@riverpod
EditorDescriptor editorDescriptor(Ref ref, String propertyId) => ref
    .read(editorDescriptorsProvider)
    .where((def) => def.propertyId == propertyId)
    .first;
