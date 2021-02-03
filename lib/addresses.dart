import 'dart:convert';
import 'dart:typed_data';

import 'package:hermez_plugin/utils/uint8_list_utils.dart';

const String hermezPrefix = 'hez:';
final hezEthereumAddressPattern = new RegExp('^hez:0x[a-fA-F0-9]{40}\$'); //
final bjjAddressPattern = new RegExp('^hez:[A-Za-z0-9_-]{44}\$');
final accountIndexPattern = new RegExp('^hez:[a-zA-Z0-9]{2,6}:[0-9]{0,9}\$');

/// Get the hermez address representation of an ethereum address
///
/// @param {String} ethereumAddress
///
/// @returns {String}
String getHermezAddress(String ethereumAddress) {
  return hermezPrefix + ethereumAddress;
}

/// Gets the ethereum address part of a Hermez address
///
/// @param {String} hezEthereumAddress
///
/// @returns {String}
String getEthereumAddress(String hezEthereumAddress) {
  if (hezEthereumAddress != null &&
      hezEthereumAddress.startsWith(hermezPrefix)) {
    return hezEthereumAddress.replaceFirst(hermezPrefix, '');
  } else {
    return hezEthereumAddress;
  }
}

/// Checks if given string matches regex of a Hermez address
///
/// @param {String} test
///
/// @returns {bool}
bool isHermezEthereumAddress(String test) {
  if (hezEthereumAddressPattern.hasMatch(test)) {
    return true;
  }
  return false;
}

/// Checks if given string matches regex of a Hermez BJJ address
///
/// @param {String} test
///
/// @returns {bool}
bool isHermezBjjAddress(String test) {
  if (bjjAddressPattern.hasMatch(test)) {
    return true;
  }
  return false;
}

/// Extracts the account index from the address with the hez prefix
///
/// @param {String} hezAccountIndex - Account index with hez prefix e.g. hez:DAI:4444
///
/// @returns {num} accountIndex - e.g. 4444
num getAccountIndex(String hezAccountIndex) {
  if (hezAccountIndex != null) {
    int colonIndex = hezAccountIndex.lastIndexOf(':') + 1;
    return num.parse(hezAccountIndex.substring(colonIndex));
  } else {
    return -1;
  }
}

/// Checks if given string matches regex of a Hermez account index
/// @param {String} test
/// @returns {Boolean}
bool isHermezAccountIndex(String test) {
  if (accountIndexPattern.hasMatch(test)) {
    return true;
  }
  return false;
}

/// Get API Bjj compressed data format
/// @param {String} bjjCompressedHex Bjj compressed address encoded as hex string
/// @returns {String} API adapted bjj compressed address
String hexToBase64BJJ(String bjjCompressedHex) {
  // swap endian
  BigInt bjjScalar = Uint8ArrayUtils.bytesToBigInt(
      Uint8ArrayUtils.uint8ListfromString(
          bjjCompressedHex)); // Scalar.fromString(bjjCompressedHex, 16);
  Uint8List bjjBuff = Uint8ArrayUtils.leInt2Buff(bjjScalar, 32);
  String bjjSwap =
      Uint8ArrayUtils.bytesToBigInt(bjjBuff).toRadixString(16).padLeft(64, '0');

  Uint8List bjjSwapBuffer = Uint8ArrayUtils.uint8ListfromString(
      bjjSwap); //Buffer.from(bjjSwap, 'hex')

  var sum = 0;

  for (var i = 0; i < bjjSwapBuffer.length; i++) {
    sum += bjjSwapBuffer[i];
    sum = sum % 2 * 8;
  }

  /*Uint8List sumBuff = Uint8List(1); //Buffer.alloc(1)
  sumBuff[0] = sum; //writeUInt8(sum)*/

  final BytesBuilder finalBuffBjj = BytesBuilder();
  finalBuffBjj.add(bjjSwapBuffer.toList());
  finalBuffBjj.addByte(sum);

  //Uint8List finalBuffBjj = Uint8List.from([bjjSwapBuffer, sumBuff]);

  return 'hez:${base64Url.encode(finalBuffBjj.toBytes())}';
}
