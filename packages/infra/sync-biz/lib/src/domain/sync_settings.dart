import 'package:app_core/object.dart';

part 'sync_settings.freezed.dart';
part 'sync_settings.g.dart';

@freezed
abstract class SyncSettings with _$SyncSettings {
  const factory SyncSettings({
    /// 同步开关
    @Default(false) bool enable,

    /// 自动同步
    /// true: 数据变动后立即尝试上传
    /// false: 仅存储在本地，等待用户手动点击"同步"按钮
    @Default(true) bool autoSync,

    /// 实时同步开关, 接收变更通知
    @Default(true) bool realtimeSync,
  }) = _SyncSettings;

  factory SyncSettings.fromJson(Map<String, dynamic> json) =>
      _$SyncSettingsFromJson(json);
}
