import 'package:app_core/object.dart';

import '../domain/property_config.dart';

part 'property_draft_state.freezed.dart';

@freezed
abstract class PropertyDraftState with _$PropertyDraftState {
  const PropertyDraftState._();

  const factory PropertyDraftState({
    required String remoteSpec,
    required String currentSpec,
    required PropertyConfigBody remote, // 基准值
    required PropertyConfigBody draft, // 编辑值
    @Default(false) bool isSaving,
    @Default(false) bool isFocused,
    String? error,
  }) = _PropertyDraftState;

  bool get isDirty => remote != draft;
}
