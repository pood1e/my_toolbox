import 'package:app_core/di.dart';

import 'property_editor_descriptor.dart';
import 'property_editors/icon_editor.dart';
import 'property_editors/name_editor.dart';

part 'property_editor_registry.g.dart';

@riverpod
List<PropertyEditorDescriptor> propertyEditorDescriptors(Ref ref) => [
  nameEditor,
  iconEditor,
];

@riverpod
PropertyEditorDescriptor propertyEditorDescriptor(Ref ref, String propertyId) =>
    ref
        .read(propertyEditorDescriptorsProvider)
        .where((def) => def.propertyId == propertyId)
        .first;
