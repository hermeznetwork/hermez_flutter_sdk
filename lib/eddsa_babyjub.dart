import 'dart:ffi';
import 'dart:typed_data';

import 'package:hermez_plugin/utils/uint8_list_utils.dart';

import 'libs/circomlib.dart';
import 'utils/structs.dart' as Structs;

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
      throw new ArgumentError('buf must be 64 bytes');
    }
    CircomLib circomLib = CircomLib();
    final sigPointer = circomLib.unpackSignature(buf);
    final bufSignature = Uint8ArrayUtils.fromPointer(sigPointer, 64);
    final xList = bufSignature.sublist(0, 16);
    final yList = bufSignature.sublist(16, 32);
    final rSList = bufSignature.sublist(32, 64);
    final xPtr = Uint8ArrayUtils.toPointer(xList);
    final yPtr = Uint8ArrayUtils.toPointer(yList);
    final sPtr = Uint8ArrayUtils.toPointer(rSList);
    final Structs.Point point = Structs.Point.allocate(xPtr, yPtr);
    final pointPtr = point.addressOf;
    final Structs.Signature sig = Structs.Signature.allocate(pointPtr, sPtr);
    if (sig.r_b8 == null) {
      throw new ArgumentError('unpackSignature failed');
    }
    BigInt x = Uint8ArrayUtils.leBuff2int(xList);
    BigInt y = Uint8ArrayUtils.leBuff2int(yList);
    List<BigInt> r8 = List<BigInt>();
    r8.add(x);
    r8.add(y);

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
      throw new ArgumentError('buf must be 32 bytes');
    }
    CircomLib circomLib = CircomLib();
    final p = circomLib.unpackPoint(compressedBuffLE);
    if (p == null) {
      throw new ArgumentError('unpackPoint failed');
    }
    Uint8List buf = Uint8ArrayUtils.fromPointer(p, 32);
    final xList = buf.sublist(0, 16);
    final yList = buf.sublist(16, 32);
    BigInt x = Uint8ArrayUtils.bytesToBigInt(xList);
    BigInt y = Uint8ArrayUtils.bytesToBigInt(yList);
    List<BigInt> point = List<BigInt>();
    point.add(x);
    point.add(y);
    return new PublicKey(point);
  }

  /// Compress the PublicKey
  /// @returns {Uint8List} - point compressed into a buffer
  BigInt compress() {
    CircomLib circomLib = CircomLib();
    Uint8List xList = Uint8ArrayUtils.bigIntToBytes(p[0]);
    Uint8List yList = Uint8ArrayUtils.bigIntToBytes(p[1]);
    List<int> pointList = xList.toList();
    pointList.addAll(yList.toList());
    BigInt result = Uint8ArrayUtils.leBuff2int(Uint8List.fromList(pointList));
    return Uint8ArrayUtils.leBuff2int(circomLib.packPoint(result));
  }

  bool verify(String messageHash, Signature signature) {
    CircomLib circomLib = CircomLib();
    List<int> pointList = List<int>();
    pointList.add(p[0].toInt());
    pointList.add(p[1].toInt());
    List<int> sigList = List<int>();
    sigList.add(signature.r8[0].toInt());
    sigList.add(signature.r8[1].toInt());
    sigList.add(signature.s.toInt());
    circomLib.verifyPoseidon(
        Uint8ArrayUtils.uint8ListToString(Uint8List.fromList(pointList)),
        Uint8List.fromList(sigList),
        messageHash);
  }
}

/// Class representing EdDSA Baby Jub private key
class PrivateKey {
  Uint8List sk;

  /// Create a PrivateKey from a 32 byte Buffer
  /// @param {Uint8List} buf - private key
  PrivateKey(Uint8List buf) {
    if (buf.length != 32) {
      throw new ArgumentError('buf must be 32 bytes');
    }
    this.sk = buf;
  }

  /// Retrieve PublicKey of the PrivateKey
  /// @returns {PublicKey} PublicKey derived from PrivateKey
  PublicKey public() {
    CircomLib circomLib = CircomLib();
    Pointer<Uint8> pubKeyPtr =
        circomLib.prv2pub(Uint8ArrayUtils.uint8ListToString(this.sk));
    final bufPubKey = Uint8ArrayUtils.fromPointer(pubKeyPtr, 32);
    final xList = bufPubKey.sublist(0, 16);
    final yList = bufPubKey.sublist(16, 32);
    BigInt x = Uint8ArrayUtils.bytesToBigInt(xList);
    BigInt y = Uint8ArrayUtils.bytesToBigInt(yList);
    List<BigInt> p = List<BigInt>();
    p.add(x);
    p.add(y);
    return new PublicKey(p);
  }

  BigInt sign(BigInt messageHash) {
    CircomLib circomLib = CircomLib();
    Pointer<Uint8> signature = circomLib.signPoseidon(
        Uint8ArrayUtils.uint8ListToString(this.sk), messageHash.toString());
    final sign = Uint8ArrayUtils.fromPointer(signature, 64);
    return Uint8ArrayUtils.leBuff2int(sign);
  }
}

Uint8List packSignature(Uint8List signature) {
  CircomLib circomLib = CircomLib();
  final sigPtr = Uint8ArrayUtils.leBuff2int(signature);
  return circomLib.packSignature(sigPtr);
}

/*Point poseidon(Uint8List input) {
  final ptr = Uint8ArrayUtils.toPointer(input);
  final resultPtr = hashPoseidon(ptr);
  return resultPtr.ref;
}*/
