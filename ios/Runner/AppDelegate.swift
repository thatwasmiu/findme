import CoreLocation
import Flutter
import UIKit

/// Besides the usual Flutter start-up: "significant location change" monitoring for the tracker
/// (lib/features/tracker/data/wake_channel.dart). While it runs, iOS relaunches Find Me in the background after
/// ~500 m of movement, even after the system terminated it, and each event tells Dart to start GPS again.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private let significant = CLLocationManager()
  private var channel: FlutterMethodChannel?

  /// A background relaunch opens no window, so the storyboard's (implicit) engine is never created: this one runs
  /// `main()` instead, which resumes tracking.
  private var backgroundEngine: FlutterEngine?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    significant.delegate = self
    if launchOptions?[.location] != nil {
      // Apple: restart the service on every relaunch, or it stops delivering.
      significant.startMonitoringSignificantLocationChanges()
      let engine = FlutterEngine(name: "findme.background")
      engine.run()
      GeneratedPluginRegistrant.register(with: engine)
      listen(on: engine.binaryMessenger)
      backgroundEngine = engine
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The user opened the app: one engine is enough, the window's one takes over tracking.
    // ponytail: a fix the background engine was writing at this moment can be lost; hand the engine to the
    // window instead (FlutterViewController(engine:)) if that shows up as gaps.
    backgroundEngine?.destroyContext()
    backgroundEngine = nil
    listen(on: engineBridge.applicationRegistrar.messenger())
  }

  private func listen(on messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "findme/tracker", binaryMessenger: messenger)
    ch.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "startSignificant":
        self?.significant.startMonitoringSignificantLocationChanges()
        result(nil)
      case "stopSignificant":
        self?.significant.stopMonitoringSignificantLocationChanges()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    channel?.invokeMethod("wake", arguments: nil)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
