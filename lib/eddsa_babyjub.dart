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
// eddsa.unpackSignature -> decompress_signature

// Result<Signature,String>
typedef DecompressSignatureFunc = Pointer<Structs.Signature> Function(
    Pointer<Uint8>);
typedef DecompressSignatureFuncNative = Pointer<Structs.Signature> Function(
    Pointer<Uint8>);
final DecompressSignatureFunc decompressSignature = nativeExampleLib
    .lookup<NativeFunction<DecompressSignatureFuncNative>>(
        "decompress_signature")
    .asFunction();

// eddsa.prv2pub -> prv2pub
typedef Prv2pubFunc = Pointer<Structs.Point> Function(Pointer<Uint8>);
typedef Prv2pubFuncNative = Pointer<Structs.Point> Function(Pointer<Uint8>);
final Prv2pubFunc prv2pub = nativeExampleLib
    .lookup<NativeFunction<Prv2pubFuncNative>>("prv2pub")
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
    final sigPointer = decompressSignature(pointer);
    final Structs.Signature sig = sigPointer.ref;
    if (sig.r_b8 == null) {
      throw new Error(); // unpackSignature failed
    }
    List<BigInt> r8 = List<BigInt>(2);
    r8.add(BigInt.from(num.parse(Utf8.fromUtf8(sig.r_b8.ref.x))));
    r8.add(BigInt.from(num.parse(Utf8.fromUtf8(sig.r_b8.ref.y))));
    //return new Signature(r8, sig.s);
    return null;
  }
}

/// Class representing a EdDSA Baby Jub public key
class PublicKey {
  List<BigInt> p;

  /// Create a PublicKey from a curve point p
  /// @param {List[BigInt]} p - curve point
  PublicKey(p) {
    this.p = p;
  }

  /// Create a PublicKey from a bigInt compressed pubKey
  ///
  /// @param {BigInt} compressedBigInt - compressed public key in a bigInt
  ///
  /// @returns {PublicKey} public key class
  static PublicKey newFromCompressed(Pointer<Uint8> compressedBigInt) {
    final Uint8List compressedBuffLE =
        Uint8ArrayUtils.fromPointer(compressedBigInt, 32);
    //leInt2Buff(compressedBigInt, 32);
    if (compressedBuffLE.length != 32) {
      throw new Error(/*'buf must be 32 bytes'*/);
    }

    //const p = circomlib.babyJub.unpackPoint(compressedBuffLE)
    /*if (p == null) {
      throw new Error(/*'unpackPoint failed'*/);
    }*/
    //return new PublicKey(p);
  }

  /// Compress the PublicKey
  /// @returns {Uint8List} - point compressed into a buffer
  Uint8List compress() {
    //return Uint8ArrayUtils.fromPointer(this.p);
    //return utils.leBuff2int(circomlib.babyJub.packPoint(this.p));
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
}
