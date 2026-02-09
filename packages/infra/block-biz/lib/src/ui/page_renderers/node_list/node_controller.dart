import 'package:app_core/di.dart';
import 'package:app_core/utils.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../../../domain/data_type.dart';
import '../../../domain/node.dart';
import '../../../domain/property.dart';
import '../../../mappers/property_mapper.dart';
import '../../../repository/node_repository.dart';
import '../../../repository/property_repository.dart';
import '../../../supports/property_descriptor_registry.dart';
import 'node_state.dart';

part 'node_controller.g.dart';

@riverpod
class NodeController extends _$NodeController {
  @override
  Stream<List<Node>> build() async* {
    final repo = await ref.watch(nodeRepositoryProvider.future);
    yield* repo.watchRecentNodes();
  }

  Future<String> createNode() async {
    final id = nanoid(10);
    final repo = await ref.read(nodeRepositoryProvider.future);
    await repo.createNode(Node(id: id));
    return id;
  }
}

@riverpod
Stream<NodeState> nodeState(Ref ref, String nodeId) async* {
  final repo = await ref.watch(propertyRepositoryProvider.future);
  final nameDescriptor = ref.read(propertyDescriptorProvider('_name'));
  final iconDescriptor = ref.read(propertyDescriptorProvider('_icon'));
  final map = {
    PropertyKey(nodeId: nodeId, defId: nameDescriptor.propertyId):
        nameDescriptor.dateType.definition.storageType,
    PropertyKey(nodeId: nodeId, defId: iconDescriptor.propertyId):
        iconDescriptor.dateType.definition.storageType,
  };
  yield* repo.watchProperties(map).map((properties) {
    final nameState = properties
        .firstWhereOrNull(
          (property) => property.key.defId == nameDescriptor.propertyId,
        )
        .toState<String>(
          nameDescriptor.dateType.definition as DataTypeDefinition<String>,
        );

    final iconState = properties
        .firstWhereOrNull(
          (property) => property.key.defId == iconDescriptor.propertyId,
        )
        .toState<IconData>(
          iconDescriptor.dateType.definition as DataTypeDefinition<IconData>,
        );
    return NodeState(name: nameState, icon: iconState);
  });
}
