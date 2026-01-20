package me.pood1e.toolbox.my_toolbox

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "me.pood1e/boot_id").setMethodCallHandler { call, result ->
            if (call.method == "getBootId") {
                // 获取 Android 的启动次数计数器，重启后该值会 +1
                val bootCount = Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, 0)
                result.success(bootCount.toString())
            } else {
                result.notImplemented()
            }
        }
    }
}
