import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';
part 'result.g.dart';

/// 通用 API 响应封装
/// T 是 data 字段的类型
@Freezed(genericArgumentFactories: true)
abstract class R<T> with _$R<T> {
  const R._(); // 私有构造函数，用于添加 getter

  const factory R({
    /// 状态码 (200 为成功)
    required int code,

    /// 消息提示
    required String message,

    /// 泛型数据，可能为空
    T? data,
  }) = _R;

  /// 反序列化方法
  /// [fromJsonT] 是一个回调函数，告诉 Dart 如何将 JSON 转为 T 类型
  factory R.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$RFromJson(json, fromJsonT);

  /// 辅助判断是否成功
  bool get isSuccess => code == 200;
}
