import 'package:app_core/object.dart';
import 'package:flutter/material.dart';

import '../../state/property_state.dart';

part 'node_state.freezed.dart';

@freezed
abstract class NodeState with _$NodeState {
  const factory NodeState({
    required PropertyState<String> name,
    required PropertyState<IconData> icon,
  }) = _NodeState;
}
