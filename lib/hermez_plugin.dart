import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

///////////////////////////////////////////////////////////////////////////////
// Typedef's
///////////////////////////////////////////////////////////////////////////////

typedef RustGreetingFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef RustGreetingFuncNative = Pointer<Utf8> Function(Pointer<Utf8>);

///////////////////////////////////////////////////////////////////////////////
// Load the library
///////////////////////////////////////////////////////////////////////////////

final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libbabyjubjub.so")
    : DynamicLibrary.process();

///////////////////////////////////////////////////////////////////////////////
// Locate the symbols we want to use
///////////////////////////////////////////////////////////////////////////////

// Result<Signature,String>
typedef DecompressSignatureFunc = Pointer<Uint8> Function(Pointer<Uint8>);
typedef DecompressSignatureFuncNative = Pointer<Uint8> Function(Pointer<Uint8>);
final DecompressSignatureFunc decompressSignature = nativeExampleLib
    .lookup<NativeFunction<DecompressSignatureFuncNative>>(
        "decompress_signature")
    .asFunction();

final RustGreetingFunc rustGreeting = nativeExampleLib
    .lookup<NativeFunction<RustGreetingFuncNative>>("rust_greeting")
    .asFunction();

typedef NewMethodFunc = Pointer<Utf8> Function(Pointer<Uint8>);
typedef NewMethodFuncNative = Pointer<Utf8> Function(Pointer<Uint8>);
final NewMethodFunc newMethod = nativeExampleLib
    .lookup<NativeFunction<NewMethodFuncNative>>("new_method")
    .asFunction();

typedef FreeStringFunc = void Function(Pointer<Utf8>);
typedef FreeStringFuncNative = Void Function(Pointer<Utf8>);
final FreeStringFunc freeCString = nativeExampleLib
    .lookup<NativeFunction<FreeStringFuncNative>>("rust_cstr_free")
    .asFunction();

// Result<Signature, String>* init_product(Product*, char* name, int price)

typedef Result_Signature_String = Pointer<Uint8> Function(
    Pointer<Uint8> context, Pointer<Uint8> name);
typedef InitProductFuncNative = Pointer<Uint8> Function(
    Pointer<Uint8> context, Pointer<Uint8> name);
final Result_Signature_String result = nativeExampleLib
    .lookup<NativeFunction<InitProductFuncNative>>("init_product")
    .asFunction();

///////////////////////////////////////////////////////////////////////////////
// HANDLERS
///////////////////////////////////////////////////////////////////////////////
/*String nativeDecompressSignature(Uint8List buf) {
  if (nativeExampleLib == null)
    return "ERROR: The library is not initialized 🙁";

  print("- Mylib bindings found 👍");
  print("  ${nativeExampleLib.toString()}"); // Instance info

  //final argName = Utf8.toUtf8(buf);
  print("- Calling new method with argument:  $buf");

  // Create a pointer
  //final p = allocate<Coordinate>();
  // Place a value into the address
  //p.value = Coordinate.allocate(0, 0);

  final pointer = allocate<Uint8>();
  pointer.value = 0;
  print(pointer.value);
  //final coordinate = pointer.load();
  //Pointer<Uint8>
  //final pointer = allocate<IntPtr>();
  //Uint8Pointer.value = buf;
  // The actual native call
  final resultPointer = decompressSignature(pointer);
  //final resultPointer = newMethod(pointer);
  print("- Result pointer:  $resultPointer");

  //final coordinate = resultPointer.load();

  final greetingStr = Utf8.fromUtf8(resultPointer);
  print("- Response string:  $greetingStr");

  // Free the string pointer, as we already have
  // an owned String to return
  print("- Freeing the native char*");
  //freeCString(resultPointer);
  return '';
  //return greetingStr;
}*/

String nativeGreeting(String name) {
  if (nativeExampleLib == null)
    return "ERROR: The library is not initialized 🙁";

  print("- Mylib bindings found 👍");
  print("  ${nativeExampleLib.toString()}"); // Instance info

  final argName = name.toNativeUtf8();
  print("- Calling rust_greeting with argument:  $argName");

  // The actual native call
  final resultPointer = rustGreeting(argName);
  print("- Result pointer:  $resultPointer");

  final greetingStr = resultPointer.toDartString();
  print("- Response string:  $greetingStr");

  // Free the string pointer, as we already have
  // an owned String to return
  print("- Freeing the native char*");
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
