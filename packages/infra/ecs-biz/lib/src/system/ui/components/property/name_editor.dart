import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/cupertino.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';
import '../../../meta/registry/name_meta.dart';
import '../../component_widget.dart';
import '../basic/text_input.dart';
import 'property_card.dart';

part 'name_editor.g.dart';

@riverpod
Stream<String?> watchNodeNameVal(Ref ref, String nodeId) async* {
  final service = await ref.watch(configServiceProvider.future);
  yield* service.watch(PropertyId(nodeId: nodeId, metaId: '_name')).map((
    result,
  ) {
    if (result == null) {
      return null;
    }
    return result.text;
  });
}

@riverpod
class NameEditorController extends _$NameEditorController {
  @override
  Stream<NameConfig> build(String nodeId) async* {
    final srv = await ref.watch(configServiceProvider.future);
    yield* srv
        .watch(PropertyId(nodeId: nodeId, metaId: '_name'))
        .map((cfg) => cfg as NameConfig);
  }

  Future<void> updateProperty(String text) async {
    final service = await ref.read(configServiceProvider.future);
    await service.update(
      PropertyId(nodeId: nodeId, metaId: '_name'),
      await future,
      NameConfig(text: text),
    );
  }

  Future<void> deleteProperty() async {
    final service = await ref.read(configServiceProvider.future);
    await service.delete(PropertyId(nodeId: nodeId, metaId: '_name'));
  }
}

class NamePropertyComponent implements PropertyWidget {
  @override
  PropertyComponentBuilder get builder =>
      (nodeId, _) => NameEditorWidget(nodeId: nodeId);

  @override
  String get id => 'name_editor';

  @override
  String get metaId => '_name';
}

class NameEditorWidget extends ConsumerWidget {
  final String _nodeId;

  const NameEditorWidget({super.key, required String nodeId})
    : _nodeId = nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valAsync = ref.watch(nameEditorControllerProvider(_nodeId));
    final notifier = ref.read(nameEditorControllerProvider(_nodeId).notifier);

    return PropertyCardWidget(
      config: PropertyCardConfig(
        metaId: '_name',
        onDeleted: notifier.deleteProperty,
        compactContent: Expanded(
          child: valAsync.whenUI(
            data: (config) => TextInputWidget(
              config: TextInputConfig(
                initialText: config.text,
                onChanged: notifier.updateProperty,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
