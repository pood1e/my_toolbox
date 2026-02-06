import 'package:app_core/object.dart';

import '../../domain/stored_value.dart';

part 'property_state.freezed.dart';

@freezed
sealed class PropertyState<T> with _$PropertyState<T> {
  /// 状态 1: 正常，持有有效值
  const factory PropertyState.idle({required T value}) = Idle<T>;

  /// 状态 2: 正在计算
  /// UI 可以根据之前的值 (oldValue) 做一个优雅的加载过渡，而不是直接显示空白
  const factory PropertyState.calculating({T? oldValue}) = Calculating<T>;

  /// 状态 3: 计算出错
  const factory PropertyState.error({required ValueError errorType}) = Error<T>;

  /// 状态 4: 未初始化或无数据
  /// 比如一个新节点还没有任何属性时
  const factory PropertyState.uninitialized() = Uninitialized<T>;
}
