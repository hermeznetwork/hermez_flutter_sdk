import Flutter
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
    pack_signature("");
    unpack_signature("");
    pack_point("", "");
    unpack_point("");
    prv2pub("");
    hash_poseidon("", "", "", "", "", "");
    sign_poseidon("", "");
    verify_poseidon("", "", "");
    let str = "string"
    let unsafePointer = UnsafeMutablePointer<Int8>(mutating: (str as NSString).utf8String)
    cstring_free(unsafePointer);
  }
}
