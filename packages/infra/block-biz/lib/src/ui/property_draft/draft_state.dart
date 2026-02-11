import 'package:app_core/object.dart';

import '../../domain/property_config.dart';

part 'draft_state.freezed.dart';

///

@freezed
abstract class DraftState with _$DraftState {
  const DraftState._();

  const factory DraftState({
    required String remoteSpec,
    required String currentSpec,
    required PropertyConfigBody remote, // 基准值
    required PropertyConfigBody draft, // 编辑值
    @Default(false) bool isSaving,
    @Default(false) bool isFocused,
    String? error,
  }) = _DraftState;

  bool get isDirty => remote != draft;


}
