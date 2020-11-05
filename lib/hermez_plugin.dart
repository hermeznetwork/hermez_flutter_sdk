import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

///////////////////////////////////////////////////////////////////////////////
// Typedef's
///////////////////////////////////////////////////////////////////////////////

typedef RustGreetingFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef RustGreetingFuncNative = Pointer<Utf8> Function(Pointer<Utf8>);

typedef DecompressSignatureFunc = Pointer<Uint8> Function(Pointer<Uint8>);
typedef DecompressSignatureFuncNative = Pointer<Uint8> Function(Pointer<Uint8>);

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

final DecompressSignatureFunc decompressSignature = nativeExampleLib
    .lookup<NativeFunction<DecompressSignatureFuncNative>>(
        "decompress_signature")
    .asFunction();

final RustGreetingFunc rustGreeting = nativeExampleLib
    .lookup<NativeFunction<RustGreetingFuncNative>>("rust_greeting")
    .asFunction();

/*final FreeStringFunc freeCString = nativeExampleLib
    .lookup<NativeFunction<FreeStringFuncNative>>("rust_cstr_free")
    .asFunction();*/

///////////////////////////////////////////////////////////////////////////////
// HANDLERS
///////////////////////////////////////////////////////////////////////////////
String nativeDecompressSignature(Uint8List buf) {
  if (nativeExampleLib == null)
    return "ERROR: The library is not initialized 🙁";

  print("- Mylib bindings found 👍");
  print("  ${nativeExampleLib.toString()}"); // Instance info

  //final argName = Utf8.toUtf8(buf);
  print("- Calling decompress Signature with argument:  $buf");

  final pointer = allocate<Uint8>();
  pointer.value = 3;
  print(pointer.value);
  //Pointer<Uint8>
  //final pointer = allocate<IntPtr>();
  //Uint8Pointer.value = buf;
  // The actual native call
  final resultPointer = decompressSignature(pointer);
  print("- Result pointer:  $resultPointer");

  /*final greetingStr = Utf8.fromUtf8(resultPointer);
  print("- Response string:  $greetingStr");*/

  // Free the string pointer, as we already have
  // an owned String to return
  print("- Freing the native char*");
  //freeCString(resultPointer);
  return '';
  //return greetingStr;
}

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
  //freeCString(resultPointer);

  return greetingStr;
}

class HermezPlugin {
  static const MethodChannel _channel = const MethodChannel('hermez_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
