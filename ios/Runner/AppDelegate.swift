import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let defaults = UserDefaults(suiteName: "group.com.mediasis.dashboardapp.onesignal")
    defaults?.set(false, forKey: "app_is_active")
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { _ in defaults?.set(true, forKey: "app_is_active") }
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { _ in defaults?.set(false, forKey: "app_is_active") }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "NativePrinterBridge"
    ) else { return }
    let channel = FlutterMethodChannel(
      name: "com.mediasis.dashboardapp/printing",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard let defaults = UserDefaults(
        suiteName: "group.com.mediasis.dashboardapp.onesignal"
      ) else {
        result(FlutterError(code: "app_group", message: "App Group unavailable", details: nil))
        return
      }
      switch call.method {
      case "synchronize":
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "arguments", message: "Invalid arguments", details: nil))
          return
        }
        defaults.set(arguments["business_location_id"] as? String ?? "", forKey: "business_location_id")
        defaults.set(arguments["printers"] as? [[String: Any]] ?? [], forKey: "printers")
        result(nil)
      case "takeJobs":
        let jobs = defaults.array(forKey: "completed_jobs") ?? []
        defaults.set([], forKey: "completed_jobs")
        result(jobs)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
