import 'package:app_core/di.dart';
import 'package:nanoid/nanoid.dart';

import '../../../domain/shared.dart';
import '../../../models/models.dart';
import '../../../repository/trait_repository.dart';
import '../../dispatchor/dispatchor_controller.dart';

part 'node_editor_controller.g.dart';

@riverpod
class NodeEditorController extends _$NodeEditorController {
  @override
  Future<List<Trait>> build(String nodeId) async {
    return await ref.watch(nodeTraitsStreamProvider(nodeId).future);
  }

  Future<void> createDefaultNameTrait() async {
    final traitId = nanoid();
    final defaultValue = 'unnamed';
    final repo = await ref.read(traitRepositoryProvider.future);
    await repo.installTrait(
      trait: Trait(
        id: traitId,
        traitType: TraitType.name,
        nodeId: nodeId,
        isValid: true,
      ),
      fields: [
        Field(
          id: nanoid(),
          traitId: traitId,
          valueType: ValueType.string,
          traitType: TraitType.name,
          traitKey: null,
          hasRef: false,
          cacheable: true,
          isValid: true,
          config: {'data': defaultValue},
          data: defaultValue,
        ),
      ],
    );
  }

  Future<void> createDefaultIconTrait() async {
    final traitId = nanoid();
    final repo = await ref.read(traitRepositoryProvider.future);
    await repo.installTrait(
      trait: Trait(
        id: traitId,
        traitType: TraitType.icon,
        nodeId: nodeId,
        isValid: false,
      ),
      fields: [
        Field(
          id: nanoid(),
          traitId: traitId,
          valueType: ValueType.json,
          traitType: TraitType.icon,
          traitKey: null,
          hasRef: false,
          cacheable: true,
          isValid: false,
        ),
      ],
    );
  }
}
