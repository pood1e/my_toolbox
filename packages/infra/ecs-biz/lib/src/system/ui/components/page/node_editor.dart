import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../../config/config_service.dart';
import '../../component_widget.dart';
import '../property/name_view.dart';

part 'node_editor.freezed.dart';
part 'node_editor.g.dart';

@freezed
abstract class NodeEditorConfig with _$NodeEditorConfig {
  const factory NodeEditorConfig({required String nodeId}) = _NodeEditorConfig;
}

class NodeEditorComponent implements ComponentWidget {
  @override
  String get id => 'node_editor';

  @override
  WidgetType get type => WidgetType.page;

  @override
  ComponentBuilder get builder =>
      (_, _, cfg) => NodeEditorWidget(config: cfg);
}

@riverpod
class NodeEditorController extends _$NodeEditorController {
  @override
  Stream<Set<String>> build(String nodeId) async* {
    final service = await ref.watch(configServiceProvider.future);
    yield* service.watchMetasByNode(nodeId);
  }
}

class NodeEditorWidget extends ConsumerWidget {
  final NodeEditorConfig _config;

  const NodeEditorWidget({super.key, required NodeEditorConfig config})
    : _config = config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(watchNodeNameValProvider(_config.nodeId));
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(nameAsync.value ?? 'unnamed'),
      ),
    );
  }
}
