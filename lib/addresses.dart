import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_sdk/utils.dart';
import 'package:hermez_sdk/utils/uint8_list_utils.dart';
import 'package:web3dart/crypto.dart';

const String hermezPrefix = 'hez:';
final ethereumAddressPattern = new RegExp('^0x[a-fA-F0-9]{40}\$');
final hezEthereumAddressPattern = new RegExp('^hez:0x[a-fA-F0-9]{40}\$'); //
final bjjAddressPattern = new RegExp('^hez:[A-Za-z0-9_-]{44}\$');
final accountIndexPattern = new RegExp('^hez:[a-zA-Z0-9]{2,6}:[0-9]{0,9}\$');

/// Get the hermez address representation of an ethereum address
///
/// @param [String] ethereumAddress
/// @returns [String] - Hermez address
String getHermezAddress(String ethereumAddress) {
  return hermezPrefix + ethereumAddress;
}

/// Gets the ethereum address part of a Hermez address
///
/// @param [String] hezEthereumAddress
///
/// @returns [String] - ethereum address
String getEthereumAddress(String hezEthereumAddress) {
  if (hezEthereumAddress != null &&
      hezEthereumAddress.startsWith(hermezPrefix)) {
    return hezEthereumAddress.replaceFirst(hermezPrefix, '');
  } else {
    return hezEthereumAddress;
  }
}

/// Checks if given string matches regex of a Ethereum address
///
/// @param [String] test
/// @returns [bool] - true if is an ethereum address
bool isEthereumAddress(String test) {
  if (test != null && ethereumAddressPattern.hasMatch(test)) {
    return true;
  }
  return false;
}

/// Checks if given string matches regex of a Hermez address
///
/// @param [String] test
/// @returns [bool] - true if is a Hermez address
bool isHermezEthereumAddress(String test) {
  if (test != null && hezEthereumAddressPattern.hasMatch(test)) {
    return true;
  }
  return false;
}

/// Checks if given string matches regex of a Hermez BJJ address
///
/// @param [String] test
/// @returns [bool] - true if is a Hermez bjj address
bool isHermezBjjAddress(String test) {
  if (test != null && bjjAddressPattern.hasMatch(test) && isHermezBjjAddressValid(test)) {
    return true;
  }
  return false;
}

bool isHermezBjjAddressValid(String base64BJJ) {
  String bjjCompressedHex = base64ToHexBJJ(base64BJJ);
  BigInt bjjScalar = hexToInt(bjjCompressedHex);
  Uint8List littleEndianBytes = Uint8ArrayUtils.bigIntToBytes(bjjScalar);
  String bjjSwap =
  bytesToHex(littleEndianBytes, forcePadLength: 64, padToEvenLength: false);
  Uint8List bjjSwapBuffer = hexToBytes(bjjSwap);
  var sum = 0;
  for (var i = 0; i < bjjSwapBuffer.length; i++) {
    sum += bjjSwapBuffer[i];
    sum = sum % (pow(2, 8) as int);
  }
  if (base64BJJ.startsWith('hez:')) {
    base64BJJ = base64BJJ.replaceFirst('hez:', '');
  }
  final bjjSwapBuffer2 = base64Url.decode(base64BJJ);
  final bjjSwapBuff = bjjSwapBuffer2.toList();
  final correctSum = bjjSwapBuff.removeLast();
  return sum == correctSum;
}

/// Extracts the account index from the address with the hez prefix
///
/// @param [String] hezAccountIndex - Account index with hez prefix e.g. hez:DAI:4444
/// @returns [num] accountIndex - e.g. 4444
num getAccountIndex(String? hezAccountIndex) {
  if (hezAccountIndex != null) {
    int colonIndex = hezAccountIndex.lastIndexOf(':') + 1;
    return num.parse(hezAccountIndex.substring(colonIndex));
  } else {
    return -1;
  }
}

/// Checks if given string matches regex of a Hermez account index
///
/// @param [String] test
/// @returns [bool] - true if is a Hermez account index
bool isHermezAccountIndex(String test) {
  if (test != null && accountIndexPattern.hasMatch(test)) {
    return true;
  }
  return false;
}

/// Get API bjj compressed data format
///
/// @param [String] bjjCompressedHex - bjj compressed address encoded as hex string
/// @returns [String] API adapted bjj compressed address
String hexToBase64BJJ(String bjjCompressedHex) {
  BigInt bjjScalar = hexToInt(bjjCompressedHex);
  Uint8List littleEndianBytes = Uint8ArrayUtils.bigIntToBytes(bjjScalar);
  String bjjSwap =
      bytesToHex(littleEndianBytes, forcePadLength: 64, padToEvenLength: false);
  Uint8List bjjSwapBuffer = hexToBytes(bjjSwap);

  var sum = 0;
  for (var i = 0; i < bjjSwapBuffer.length; i++) {
    sum += bjjSwapBuffer[i];
    sum = sum % (pow(2, 8) as int);
  }

  final BytesBuilder finalBuffBjj = BytesBuilder();
  finalBuffBjj.add(bjjSwapBuffer.toList());
  finalBuffBjj.addByte(sum);

  return 'hez:${base64Url.encode(finalBuffBjj.toBytes())}';
}

/// Gets the Babyjubjub hexadecimal from its base64 representation
///
/// @param {String} base64BJJ
/// @returns {String} babyjubjub address in hex string
String base64ToHexBJJ(String base64BJJ) {
  if (base64BJJ.startsWith('hez:')) {
    base64BJJ = base64BJJ.replaceFirst('hez:', '');
  }
  final bjjSwapBuffer = base64Url.decode(base64BJJ);
  final bjjSwapBuff = bjjSwapBuffer.toList();
  bjjSwapBuff.removeLast();
  String bjjSwap =
      bytesToHex(bjjSwapBuff, forcePadLength: 64, padToEvenLength: false);
  Uint8List littleEndianBytes = hexToBytes(bjjSwap);
  BigInt bjjScalar = Uint8ArrayUtils.bytesToBigInt(littleEndianBytes);
  String bjjCompressedHex = bjjScalar.toRadixString(16);
  return bjjCompressedHex;
}

/// Get Ay and Sign from Bjj compressed
/// @param {String} fromBjjCompressed - Bjj compressed encoded as hexadecimal string
/// @return {Object} Ay represented as hexadecimal string, Sign represented as BigInt
dynamic getAySignFromBJJ(String fromBjjCompressed) {
  BigInt bjjScalar = hexToInt(fromBjjCompressed);
  String ay = extract(bjjScalar, 0, 254).toRadixString(16);
  BigInt sign = extract(bjjScalar, 255, 1);

  return {"ay": ay, "sign": sign};
}
