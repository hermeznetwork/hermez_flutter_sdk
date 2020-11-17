import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:hermez_plugin/utils/structs.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';

class CircomLib {
  final DynamicLibrary lib;
  CircomLib({@required this.lib}) {
    _packSignature = lib
        .lookup<NativeFunction<Pointer<Uint8> Function(Pointer<Signature>)>>(
            "pack_signature")
        .asFunction();

    _unpackSignature = lib
        .lookup<NativeFunction<Pointer<Signature> Function(Pointer<Uint8>)>>(
            "unpack_signature")
        .asFunction();

    _packPoint = lib
        .lookup<NativeFunction<Pointer<Uint8> Function(Pointer<Point>)>>(
            "pack_point")
        .asFunction();

    _unpackPoint = lib
        .lookup<NativeFunction<Pointer<Point> Function(Pointer<Uint8>)>>(
            "unpack_point")
        .asFunction();

    _hashPoseidon = lib
        .lookup<NativeFunction<Pointer<Point> Function(Pointer<Uint8>)>>(
            "hash_poseidon")
        .asFunction();

    _signPoseidon = lib
        .lookup<NativeFunction<Pointer<Point> Function(Pointer<Uint8>)>>(
            "sign_poseidon")
        .asFunction();

    _verifyPoseidon = lib
        .lookup<NativeFunction<Pointer<Point> Function(Pointer<Uint8>)>>(
            "verify_poseidon")
        .asFunction();
  }

  Pointer<Uint8> Function(Pointer<Signature>) _packSignature;
  Uint8List packSignature(Pointer<Uint8> signature) {
    final Uint8List buf = Uint8ArrayUtils.fromPointer(signature, 32);
    //leInt2Buff(compressedBigInt, 32);
    if (buf.length != 32) {
      throw new Error(/*'buf must be 32 bytes'*/);
    }
    //final Uint8List buf = Uint8ArrayUtils.fromPointer(signature, length);
    //final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _packSignature(buf);
    final Uint8List result = Uint8ArrayUtils.fromPointer(resultPtr, 32);
    return result;
  }

  Pointer<Signature> Function(Pointer<Uint8>) _unpackSignature;
  Signature unpackSignature(Uint8List buf) {
    final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _unpackSignature(ptr);
    return resultPtr.ref;
  }

  Pointer<Uint8> Function(Pointer<Point>) _packPoint;
  Uint8List packPoint(Pointer<Uint8> point) {
    final Uint8List buf = Uint8ArrayUtils.fromPointer(point, 32);
    //leInt2Buff(compressedBigInt, 32);
    if (buf.length != 32) {
      throw new Error(/*'buf must be 32 bytes'*/);
    }
    //final Uint8List buf = Uint8ArrayUtils.fromPointer(signature, length);
    //final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _packPoint(buf);
    final Uint8List result = Uint8ArrayUtils.fromPointer(resultPtr, 32);
    return result;
  }

  Pointer<Point> Function(Pointer<Uint8>) _unpackPoint;
  Point unpackPoint(Uint8List buf) {
    final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _unpackPoint(ptr);
    return resultPtr.ref;
  }

  // circomlib.poseidon -> hashPoseidon
  Pointer<Point> Function(Pointer<Uint8>) _hashPoseidon;
  Point hashPoseidon(Uint8List buf) {
    final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _hashPoseidon(ptr);
    return resultPtr.ref;
  }

  // privKey.signPoseidon -> signPoseidon
  Pointer<Signature> Function(Pointer<Uint8>) _signPoseidon;
  Point signPoseidon(Uint8List buf) {
    final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _signPoseidon(ptr);
    return resultPtr.ref;
  }

  // privKey.verifyPoseidon -> verifyPoseidon
  Pointer<Point> Function(Pointer<Uint8>) _verifyPoseidon;
  Point verifyPoseidon(Uint8List buf) {
    final ptr = Uint8ArrayUtils.toPointer(buf);
    final resultPtr = _verifyPoseidon(ptr);
    return resultPtr.ref;
  }
}
