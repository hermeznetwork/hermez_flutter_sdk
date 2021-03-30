import FlutterMacOS
import UIKit

public class SwiftHermezPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
     //let channel = FlutterMethodChannel(name: "hermez_plugin", binaryMessenger: registrar.messenger())
     //let instance = SwiftHermezPlugin()
     // registrar.addMethodCallDelegate(instance, channel: channel)
    // We are not using Flutter channels here
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // result("iOS " + UIDevice.current.systemVersion)
    // Noop
    result(nil)
  }


  public func dummyMethodToEnforceBundling() {
    prv2pub("");
    packSignature("");
      // rust_greeting("");
      // let oneTwo = UnsafeMutablePointer<((UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8))>.allocate(capacity: 64)
      // oneTwo.initialize(repeating: 1, count: 2)
      // new_method(oneTwo);
      // ...
      // This code will force the bundler to use these functions, but will never be called
    }
}
