import 'package:app_core/di.dart';
import 'package:app_core/utils.dart';

import '../../models/models.dart';
import '../../repository/trait_repository.dart';
import '../node_renderer.dart';
import '../node_renderers/node_renderer_registry.dart';

part 'dispatchor_controller.g.dart';

@riverpod
Stream<List<Trait>> nodeTraitsStream(Ref ref, String nodeId) async* {
  final repo = await ref.watch(traitRepositoryProvider.future);
  yield* repo.watchNodeTraits(nodeId);
}

@riverpod
Future<List<Trait>> nodeTraits(Ref ref, String nodeId) async {
  final repo = await ref.watch(traitRepositoryProvider.future);
  return repo.getNodeTraits(nodeId);
}

Future<List<NodeRenderer>> _availableRenderers(
  Ref ref,
  List<Trait> traits,
) async {
  final renderers = ref.read(nodeRendererRegistryProvider);
  final validTraits = traits.where((trait) => trait.isValid).toList();
  final validTraitTypes = validTraits.map((trait) => trait.traitType).toSet();
  return renderers
      .where((renderer) => validTraitTypes.containsAll(renderer.requiredTraits))
      .sortedBy((renderer) => renderer.priority)
      .toList();
}

@riverpod
Future<List<NodeRenderer>> availableRenderers(Ref ref, String nodeId) async {
  final traits = await ref.watch(nodeTraitsProvider(nodeId).future);
  return await _availableRenderers(ref, traits);
}

@riverpod
Stream<List<NodeRenderer>> availableRenderersStream(
  Ref ref,
  String nodeId,
) async* {
  final traits = await ref.watch(nodeTraitsStreamProvider(nodeId).future);
  final renderers = await _availableRenderers(ref, traits);
  yield renderers;
}

@riverpod
class CurrentNodeRendererController extends _$CurrentNodeRendererController {
  @override
  Future<NodeRenderer> build(String nodeId) async {
    // 只读一次, 不监听
    // final traits = await ref.read(validNodeTraitsProvider(nodeId).future);
    // todo: 实现RendererTrait指定默认打开方式

    final availables = await ref.watch(
      availableRenderersProvider(nodeId).future,
    );

    return availables[0];
  }

  Future<void> switchRenderer(String rendererId) async {
    final availables = await ref.read(
      availableRenderersProvider(nodeId).future,
    );
    final renderer = availables.firstWhereOrNull(
      (renderer) => renderer.id == rendererId,
    );
    if (renderer != null) {
      state = AsyncValue.data(renderer);
    } else {
      throw Exception('renderer is not available');
    }
  }
}
