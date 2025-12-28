import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
 let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "me.pood1e/boot_id", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getBootId" {
        // 获取内核启动 Session UUID
        var size = 0
        sysctlbyname("kern.bootsessionuuid", nil, &size, nil, 0)
        var uuid = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.bootsessionuuid", &uuid, &size, nil, 0)
        result.success(String(cString: uuid))
      } else {
        result.notImplemented()
      }
    })
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
