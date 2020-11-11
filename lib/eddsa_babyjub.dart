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
// eddsa.prv2pub ->
// Result<Signature,String>
typedef DecompressSignatureFunc = Pointer<Structs.Signature> Function(
    Pointer<Uint8>);
typedef DecompressSignatureFuncNative = Pointer<Structs.Signature> Function(
    Pointer<Uint8>);
final DecompressSignatureFunc decompressSignature = nativeExampleLib
    .lookup<NativeFunction<DecompressSignatureFuncNative>>(
        "decompress_signature")
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
    //return new Signature(sig.r_b8, sig.s);
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
  static PublicKey newFromCompressed(compressedBigInt) {
    /*const compressedBuffLE = utils.leInt2Buff(compressedBigInt, 32)
    if (compressedBuffLE.length !== 32) {
      throw new Error('buf must be 32 bytes')
    }

    const p = circomlib.babyJub.unpackPoint(compressedBuffLE)
    if (p == null) {
      throw new Error('unpackPoint failed')
    }*/
    //return new PublicKey(p);
  }

  /// Compress the PublicKey
  /// @returns {Uint8List} - point compressed into a buffer
  Uint8List compress() {
    //return utils.leBuff2int(circomlib.babyJub.packPoint(this.p));
  }
}

/// Class representing EdDSA Baby Jub private key
class PrivateKey {
  dynamic sk;

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
  public() {
    return new PublicKey(circomlib.eddsa.prv2pub(this.sk));
  }
}
