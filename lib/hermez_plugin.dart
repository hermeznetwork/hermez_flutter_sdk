import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import "package:ffi/ffi.dart";
import 'package:flutter/services.dart';

///////////////////////////////////////////////////////////////////////////////
// Typedef's
///////////////////////////////////////////////////////////////////////////////

typedef RustGreetingFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef RustGreetingFuncNative = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FreeStringFunc = void Function(Pointer<Utf8>);
typedef FreeStringFuncNative = Void Function(Pointer<Utf8>);

///////////////////////////////////////////////////////////////////////////////
// Load the library
///////////////////////////////////////////////////////////////////////////////

final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libbabyjubjub.so")
    : DynamicLibrary.process();

///////////////////////////////////////////////////////////////////////////////
// Locate the symbols we want to use
///////////////////////////////////////////////////////////////////////////////

final RustGreetingFunc rustGreeting = nativeExampleLib
    .lookup<NativeFunction<RustGreetingFuncNative>>("rust_greeting")
    .asFunction();

final FreeStringFunc freeCString = nativeExampleLib
    .lookup<NativeFunction<FreeStringFuncNative>>("rust_cstr_free")
    .asFunction();

///////////////////////////////////////////////////////////////////////////////
// HANDLERS
///////////////////////////////////////////////////////////////////////////////
String nativeGreeting(String name) {
  if (nativeExampleLib == null)
    return "ERROR: The library is not initialized 🙁";

  print("- Mylib bindings found 👍");
  print("  ${nativeExampleLib.toString()}"); // Instance info

  final argName = Utf8.toUtf8(name);
  print("- Calling rust_greeting with argument:  $argName");

  // The actual native call
  final resultPointer = rustGreeting(argName);
  print("- Result pointer:  $resultPointer");

  final greetingStr = Utf8.fromUtf8(resultPointer);
  print("- Response string:  $greetingStr");

  // Free the string pointer, as we already have
  // an owned String to return
  print("- Freing the native char*");
  freeCString(resultPointer);

  return greetingStr;
}

class HermezPlugin {
  final Pointer<Utf8> Function(Pointer<Utf8>) rustGreeting = nativeExampleLib
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
          "rust_greeting")
      .asFunction();

  final void Function(Pointer<Utf8>) freeGreeting = nativeExampleLib
      .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>("rust_cstr_free")
      .asFunction();

  static const MethodChannel _channel = const MethodChannel('hermez_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
