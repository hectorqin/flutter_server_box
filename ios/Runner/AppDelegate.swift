import UIKit
import WidgetKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    setupMethodChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func setupMethodChannel() {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    let homeWidgetMC = FlutterMethodChannel(name: "tech.lolli.toolbox/home_widget", binaryMessenger: controller.binaryMessenger)
    homeWidgetMC.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "update" {
          WidgetCenter.shared.reloadTimelines(ofKind: "StatusWidget")
          result(nil)
      }
    })
  }
}
