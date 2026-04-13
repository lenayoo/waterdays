import Flutter
import UIKit
import WidgetKit

private enum WaterWidgetStore {
  static let suiteName = "group.com.verydays.waterdays.shared"
  static let channelName = "waterdays/widget"
  static let drankKey = "drankCups"
  static let goalKey = "goalCups"
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: WaterWidgetStore.channelName,
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        guard call.method == "updateWaterProgress" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let args = call.arguments as? [String: Any],
          let drank = args["drankCups"] as? Int,
          let goal = args["goalCups"] as? Int,
          let defaults = UserDefaults(suiteName: WaterWidgetStore.suiteName)
        else {
          result(
            FlutterError(
              code: "INVALID_ARGS",
              message: "Widget progress data is missing.",
              details: nil
            )
          )
          return
        }

        defaults.set(drank, forKey: WaterWidgetStore.drankKey)
        defaults.set(goal, forKey: WaterWidgetStore.goalKey)

        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }

        result(nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
