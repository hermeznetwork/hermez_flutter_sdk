import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';

import 'utils/structs.dart' as Structs;

///////////////////////////////////////////////////////////////////////////////
// Load the library
///////////////////////////////////////////////////////////////////////////////

final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libbabyjubjub.so")
    : DynamicLibrary.process();

// babyJub.unpackPoint
// Result<Signature,String>

// eddsa.packSignature -> pack_signature
typedef PackSignatureFunc = Pointer<Uint8> Function(Pointer<Structs.Signature>);
typedef PackSignatureFuncNative = Pointer<Uint8> Function(
    Pointer<Structs.Signature>);
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
    .asFunction();

/// Class representing EdDSA Baby Jub signature
class Signature {
  List<BigInt> r8;
  BigInt s;

  /// Create a Signature with the R8 point and S scalar
  /// @param {List[BigInt]} r8 - R8 point
  /// @param {BigInt} s - BigInt
  Signature(List<BigInt> r8, BigInt s) {
    this.r8 = r8;
    this.s = s;
  }

  /// Create a Signature from a compressed Signature Buffer
  /// @param {Uint8List} buf - Buffer containing a signature
  /// @returns {Signature} Object signature
  static Signature newFromCompressed(Uint8List buf) {
    if (buf.length != 64) {
      throw new Error(); // buf must be 64 bytes
    }
    Pointer<Uint8> pointer = Uint8ArrayUtils.toPointer(buf);
    final sigPointer = unpackSignature(pointer);
    final Structs.Signature sig = sigPointer.ref;
    if (sig.r_b8 == null) {
      throw new Error(); // unpackSignature failed
    }
    List<BigInt> r8 = List<BigInt>(2);
    r8.add(BigInt.from(num.parse(Utf8.fromUtf8(sig.r_b8.ref.x))));
    r8.add(BigInt.from(num.parse(Utf8.fromUtf8(sig.r_b8.ref.y))));

    BigInt s =
        Uint8ArrayUtils.leBuff2int(Uint8ArrayUtils.fromPointer(sig.s, 32));
    return new Signature(r8, s);
  }
}

/// Class representing a EdDSA Baby Jub public key
class PublicKey {
  List<BigInt> p;

  /// Create a PublicKey from a curve point p
  /// @param {List[BigInt]} p - curve point
  PublicKey(List<BigInt> p) {
    this.p = p;
  }

  /// Create a PublicKey from a bigInt compressed pubKey
  ///
  /// @param {BigInt} compressedBigInt - compressed public key in a bigInt
  ///
  /// @returns {PublicKey} public key class
  static PublicKey newFromCompressed(BigInt compressedBigInt) {
    final Uint8List compressedBuffLE =
        Uint8ArrayUtils.leInt2Buff(compressedBigInt, 32);
    if (compressedBuffLE.length != 32) {
      throw new Error(/*'buf must be 32 bytes'*/);
    }
    final ptr = Uint8ArrayUtils.toPointer(compressedBuffLE);
    final p = unpackPoint(ptr);
    if (p == null) {
      throw new Error(/*'unpackPoint failed'*/);
    }
    Uint8List buf = Uint8ArrayUtils.fromPointer(p, 32);
    List<BigInt> point = List<BigInt>(2);
    point.add(BigInt.from(buf.elementAt(0)));
    point.add(BigInt.from(buf.elementAt(1)));
    return new PublicKey(point);
  }

  /// Compress the PublicKey
  /// @returns {Uint8List} - point compressed into a buffer
  BigInt compress() {
    //Structs.Point point = Structs.Point.allocate(
    //    Utf8.toUtf8(p[0].toString()), Utf8.toUtf8(p[1].toString()));
    List<int> pointList = List<int>(2);
    pointList.add(p[0].toInt());
    pointList.add(p[1].toInt());
    return Uint8ArrayUtils.leBuff2int(Uint8ArrayUtils.fromPointer(
        packPoint(Uint8ArrayUtils.toPointer(Uint8List.fromList(pointList))),
        32));
  }

  bool verify(String messageHash, Signature signature) {
    List<int> sigList = List<int>(3);
    sigList.add(signature.r8[0].toInt());
    sigList.add(signature.r8[1].toInt());
    sigList.add(signature.s.toInt());
    Pointer<Uint8> sigPtr = Uint8ArrayUtils.toPointer(sigList);
    Pointer<Utf8> msgPtr = Utf8.toUtf8(messageHash);
    verifyPoseidon(sigPtr, msgPtr);
  }
}

/// Class representing EdDSA Baby Jub private key
class PrivateKey {
  Uint8List sk;

  /// Create a PrivateKey from a 32 byte Buffer
  /// @param {Uint8List} buf - private key
  PrivateKey(Uint8List buf) {
    if (buf.length != 32) {
      throw new Error(/*'buf must be 32 bytes'*/);
    }
    this.sk = buf;
  }

  /// Retrieve PublicKey of the PrivateKey
  /// @returns {PublicKey} PublicKey derived from PrivateKey
  PublicKey public() {
    Pointer<Uint8> pointer = Uint8ArrayUtils.toPointer(this.sk);
    Pointer<Structs.Point> publicKey = prv2pub(pointer);
    List<BigInt> p = List<BigInt>(2);
    p.add(BigInt.from(num.parse(Utf8.fromUtf8(publicKey.ref.x))));
    p.add(BigInt.from(num.parse(Utf8.fromUtf8(publicKey.ref.y))));
    return new PublicKey(p);
  }

  BigInt sign(BigInt messageHash) {
    Pointer<Uint8> pointer = Uint8ArrayUtils.toPointer(this.sk);
    Pointer<Utf8> msgPtr = Utf8.toUtf8(messageHash.toString());
    Pointer<Uint8> signature = signPoseidon(pointer, msgPtr);
    final sign = Uint8ArrayUtils.fromPointer(signature, 64);
    return Uint8ArrayUtils.leBuff2int(sign);
  }
}

/*Point poseidon(Uint8List input) {
  final ptr = Uint8ArrayUtils.toPointer(input);
  final resultPtr = hashPoseidon(ptr);
  return resultPtr.ref;
}*/
