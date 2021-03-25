import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:hermez_plugin/utils/structs.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';

///////////////////////////////////////////////////////////////////////////////
// Load the library
///////////////////////////////////////////////////////////////////////////////

final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libbabyjubjub.so")
    : DynamicLibrary.process();

typedef PackSignatureFuncNative = Pointer<Uint8> Function(Pointer<Uint8>);
typedef PackSignatureFunc = Pointer<Uint8> Function(Pointer<Signature>);

// babyJub.unpackPoint
// Result<Signature,String>

// eddsa.packSignature -> pack_signature
/*typedef PackSignatureFunc = Pointer<Uint8> Function(Pointer<Structs.Signature>);
typedef PackSignatureFuncNative = Pointer<Uint8> Function(
    Pointer<Structs.Signature>);
final PackSignatureFunc packSignature = nativeExampleLib
    .lookup<NativeFunction<PackSignatureFuncNative>>("pack_signature")
    .asFunction();*/
/*typedef PackSignatureFunc = Pointer<Uint8> Function(Pointer<Uint8>);
typedef PackSignatureFuncNative = Pointer<Uint8> Function(Pointer<Uint8>);
final PackSignatureFunc packSignature = nativeExampleLib
    .lookup<NativeFunction<PackSignatureFuncNative>>("pack_signature")
    .asFunction();

// eddsa.unpackSignature -> unpack_signature
typedef UnpackSignatureFunc = Pointer<Structs.Signature> Function(
    Pointer<Uint8>);
typedef UnpackSignatureFuncNative = Pointer<Structs.Signature> Function(
    Pointer<Uint8>);
final UnpackSignatureFunc unpackSignature = nativeExampleLib
    .lookup<NativeFunction<UnpackSignatureFuncNative>>("unpack_signature")
    .asFunction();

// eddsa.packPoint -> pack_point
/*typedef PackPointFunc = Pointer<Uint8> Function(Pointer<Structs.Point>);
typedef PackPointFuncNative = Pointer<Uint8> Function(Pointer<Structs.Point>);
final PackPointFunc packPoint = nativeExampleLib
    .lookup<NativeFunction<PackPointFuncNative>>("pack_point")
    .asFunction();*/
typedef PackPointFunc = Pointer<Uint8> Function(Pointer<Uint8>);
typedef PackPointFuncNative = Pointer<Uint8> Function(Pointer<Uint8>);
final PackPointFunc packPoint = nativeExampleLib
    .lookup<NativeFunction<PackPointFuncNative>>("pack_point")
    .asFunction();

// eddsa.unpackPoint -> unpack_point
typedef UnpackPointFunc = Pointer<Uint8> Function(Pointer<Uint8>);
typedef UnpackPointFuncNative = Pointer<Uint8> Function(Pointer<Uint8>);
final UnpackPointFunc unpackPoint = nativeExampleLib
    .lookup<NativeFunction<UnpackPointFuncNative>>("unpack_point")
    .asFunction();

// eddsa.prv2pub -> prv2pub
typedef Prv2pubFunc = Pointer<Structs.Point> Function(Pointer<Uint8>);
typedef Prv2pubFuncNative = Pointer<Structs.Point> Function(Pointer<Uint8>);
final Prv2pubFunc prv2pub = nativeExampleLib
    .lookup<NativeFunction<Prv2pubFuncNative>>("prv2pub")
    .asFunction();

// circomlib.poseidon -> hashPoseidon
typedef hashPoseidonFunc = Pointer<Structs.Point> Function(Pointer<Uint8>);
typedef hashPoseidonFuncNative = Pointer<Structs.Point> Function(
    Pointer<Uint8>);
final hashPoseidonFunc hashPoseidon = nativeExampleLib
    .lookup<NativeFunction<hashPoseidonFuncNative>>("hashPoseidon")
    .asFunction();

// circomlib.poseidon -> signPoseidon
/*typedef signPoseidonFunc = Pointer<Structs.Signature> Function(
    Pointer<Uint8>, Pointer<Utf8>);
typedef signPoseidonNative = Pointer<Structs.Signature> Function(
    Pointer<Uint8>, Pointer<Utf8>);
final signPoseidonFunc signPoseidon = nativeExampleLib
    .lookup<NativeFunction<signPoseidonNative>>("signPoseidon")
    .asFunction();*/
typedef signPoseidonFunc = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Utf8>);
typedef signPoseidonNative = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Utf8>);
final signPoseidonFunc signPoseidon = nativeExampleLib
    .lookup<NativeFunction<signPoseidonNative>>("signPoseidon")
    .asFunction();

// circomlib.poseidon -> poseidon
typedef verifyPoseidonFunc = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Utf8>);
typedef verifyPoseidonNative = Pointer<Uint8> Function(
    Pointer<Uint8>, Pointer<Utf8>);
final verifyPoseidonFunc verifyPoseidon = nativeExampleLib
    .lookup<NativeFunction<verifyPoseidonNative>>("verifyPoseidon")
    .asFunction();*/

class CircomLib {
  final DynamicLibrary lib = Platform.isAndroid
      ? DynamicLibrary.open("libbabyjubjub.so")
      : DynamicLibrary.process();
  //final DynamicLibrary lib;
  CircomLib(/*{@required this.lib}*/) {
    _packSignature = lib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
            "pack_signature")
        .asFunction();

    _unpackSignature = lib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
            "unpack_signature")
        .asFunction();

    _packPoint = lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Utf8>, Pointer<Utf8>)>>("pack_point")
        .asFunction();

    _unpackPoint = lib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>(
            "unpack_point")
        .asFunction();

    _prv2Pub = lib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Uint8>)>>(
            "prv2pub")
        .asFunction();

    _hashPoseidon = lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>,
                    Pointer<Utf8>)>>("hash_poseidon")
        .asFunction();

    _signPoseidon = lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Uint8>, Pointer<Utf8>)>>("sign_poseidon")
        .asFunction();

    _verifyPoseidon = lib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>,
                    Pointer<Utf8>)>>("verify_poseidon")
        .asFunction();
  }

  Pointer<Utf8> Function(Pointer<Utf8>) _packSignature;
  String packSignature(String signature) {
    final sig = signature.toNativeUtf8();
    final resultPtr = _packSignature(sig);
    final result = resultPtr.toDartString();
    return result;
  }

  Pointer<Utf8> Function(Pointer<Utf8>) _unpackSignature;
  String unpackSignature(String compressedSignature) {
    final sigPtr = compressedSignature.toNativeUtf8();
    final resultPtr = _unpackSignature(sigPtr);
    final result = resultPtr.toDartString();
    return result;
  }

  Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) _packPoint;
  String packPoint(String pointX, String pointY) {
    final ptrX = pointX.toNativeUtf8();
    final ptrY = pointY.toNativeUtf8();
    final resultPtr = _packPoint(ptrX, ptrY);
    final result = resultPtr.toDartString();
    return result;
  }

  Pointer<Utf8> Function(Pointer<Utf8>) _unpackPoint;
  List<String> unpackPoint(String compressedPoint) {
    final pointPtr = compressedPoint.toNativeUtf8();
    final resultPtr = _unpackPoint(pointPtr);
    final result = resultPtr.toDartString();
    return result.split(",");
  }

  // circomlib.poseidon -> hashPoseidon
  Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>,
      Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>) _hashPoseidon;
  String hashPoseidon(String txCompressedData, String toEthAddr, String toBjjAy,
      String rqTxCompressedDatav2, String rqToEthAddr, String rqToBjjAy) {
    final ptr1 = txCompressedData.toNativeUtf8();
    final ptr2 = toEthAddr.toNativeUtf8();
    final ptr3 = toBjjAy.toNativeUtf8();
    final ptr4 = rqTxCompressedDatav2.toNativeUtf8();
    final ptr5 = rqToEthAddr.toNativeUtf8();
    final ptr6 = rqToBjjAy.toNativeUtf8();
    final resultPtr = _hashPoseidon(ptr1, ptr2, ptr3, ptr4, ptr5, ptr6);
    String resultString = resultPtr.toDartString();
    resultString = resultString.replaceAll("Fr(", "");
    resultString = resultString.replaceAll(")", "");
    return resultString;
  }

  // privKey.signPoseidon -> signPoseidon
  Pointer<Utf8> Function(Pointer<Uint8>, Pointer<Utf8>) _signPoseidon;
  String signPoseidon(Uint8List privateKey, String msg) {
    final prvKeyPtr = Uint8ArrayUtils.toPointer(privateKey);
    final msgPtr = msg.toNativeUtf8();
    final resultPtr = _signPoseidon(prvKeyPtr, msgPtr);
    final String compressedSignature = resultPtr.toDartString();
    return compressedSignature;
  }

  // privKey.verifyPoseidon -> verifyPoseidon
  Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
      _verifyPoseidon;
  bool verifyPoseidon(
      String privateKey, String compressedSignature, String msg) {
    final pubKeyPtr = privateKey.toNativeUtf8();
    final sigPtr = compressedSignature.toNativeUtf8();
    final msgPtr = msg.toNativeUtf8();
    final resultPtr = _verifyPoseidon(pubKeyPtr, sigPtr, msgPtr);
    final String resultString = resultPtr.toDartString();
    final bool result = resultString.compareTo("1") == 0;
    return result;
  }

  Pointer<Utf8> Function(Pointer<Uint8>) _prv2Pub;
  Pointer<Utf8> prv2pub(Uint8List privateKey) {
    final prvKeyPtr = Uint8ArrayUtils.toPointer(privateKey);
    final resultPtr = _prv2Pub(prvKeyPtr);
    final String resultString = resultPtr.toDartString();
    return resultPtr;
  }

  /*
  * function packSignature(sig) {
    const R8p = babyJub.packPoint(sig.R8);
    const Sp = utils.leInt2Buff(sig.S, 32);
    return Buffer.concat([R8p, Sp]);
}

function unpackSignature(sigBuff) {
    return {
        R8: babyJub.unpackPoint(sigBuff.slice(0,32)),
        S: utils.leBuff2int(sigBuff.slice(32,64))
    };
}
  * */
}
