import 'package:app_core/di.dart';
import 'package:common_ui/component.dart';
import 'package:flutter/cupertino.dart';

import '../../../config/config_service.dart';
import '../../../meta/property_meta_service.dart';
import '../../component_widget.dart';
import '../basic/text_view.dart';
import 'property_card.dart';

part 'name_view.g.dart';

@riverpod
Stream<String?> watchNodeNameVal(Ref ref, String nodeId) async* {
  final service = await ref.watch(configServiceProvider.future);
  yield* service
      .watch(PropertyId(nodeId: nodeId, metaId: '_name'))
      .map((result) => result?.text);
}

@riverpod
class NameViewController extends _$NameViewController {
  @override
  Future<String?> build(String nodeId) async =>
      await ref.watch(watchNodeNameValProvider(nodeId).future);

  Future<void> deleteProperty() async {
    final service = await ref.read(configServiceProvider.future);
    await service.delete(PropertyId(nodeId: nodeId, metaId: '_name'));
  }
}

class NamePropertyComponent implements PropertyWidget {
  @override
  PropertyComponentBuilder get builder =>
      (nodeId, _) => NameViewWidget(nodeId: nodeId);

  @override
  String get id => 'name_view';

  @override
  String get metaId => '_name';
}

class NameViewWidget extends ConsumerWidget {
  final String _nodeId;

  const NameViewWidget({super.key, required String nodeId}) : _nodeId = nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valAsync = ref.watch(nameViewControllerProvider(_nodeId));
    final notifier = ref.read(nameViewControllerProvider(_nodeId).notifier);

    return PropertyCardWidget(
      config: PropertyCardConfig(
        metaId: '_name',
        onDeleted: notifier.deleteProperty,
        content: valAsync.whenUI(
          data: (config) =>
              TextViewWidget(config: TextViewConfig(text: config!)),
        ),
      ),
    );
  }
}
