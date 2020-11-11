import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:hermez_plugin/utils/structs.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';

class BabyJubJubLib {
  final DynamicLibrary lib;
  BabyJubJubLib(@required this.lib) {
    _decompressSignature = lib.lookup <
        NativeFunction<Pointer<Uint8>>("decompress_signature").asFunction();
  }

  /*typedef DecompressSignatureFunc = Pointer<Structs.Signature> Function(
      Pointer<Uint8>);
  typedef DecompressSignatureFuncNative = Pointer<Structs.Signature> Function(
      Pointer<Uint8>);
  final DecompressSignatureFunc decompressSignature = nativeExampleLib
      .lookup<NativeFunction<DecompressSignatureFuncNative>>(
      "decompress_signature")
      .asFunction();*/

  Pointer<Signature> Function(Pointer<Uint8>) _decompressSignature;
  Signature decompressSignature(Uint8List buf) {
    final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _decompressSignature(ptr);
    return resultPtr.ref;
  }
}
