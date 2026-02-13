import 'package:app_core/di.dart';

import '../domain/compute_engine.dart';
import 'aggregator/role_rule_aggregator.dart';
import 'processor/role_rule_processor.dart';
import 'processor/simple_icon_processor.dart';
import 'processor/simple_text_processor.dart';
import 'transformer/icon_transformer.dart';

part 'support_components.g.dart';

@Riverpod(keepAlive: true)
List<Processor> processors(Ref ref) => [
  SimpleTextProcessor(),
  SimpleIconProcessor(),
  RoleRuleProcessor(ref: ref),
];

@Riverpod(keepAlive: true)
List<Transformer> transformers(Ref ref) => [IconTransformer()];

@Riverpod(keepAlive: true)
List<Aggregator> aggregators(Ref ref) => [RoleRuleAggregator()];
