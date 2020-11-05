import Flutter
import UIKit

public class SwiftHermezPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hermez_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftHermezPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func dummyMethodToEnforceBundling() {
      decompress_signature();
      // ...
      // This code will force the bundler to use these functions, but will never be called
    }
}
