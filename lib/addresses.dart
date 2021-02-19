import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_plugin/utils/uint8_list_utils.dart';
import 'package:web3dart/crypto.dart';

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
  BigInt bjjScalar = hexToInt(bjjCompressedHex);
  Uint8List littleEndianBytes = Uint8ArrayUtils.bigIntToBytes(bjjScalar);
  String bjjSwap =
      bytesToHex(littleEndianBytes, forcePadLength: 64, padToEvenLength: false);
  Uint8List bjjSwapBuffer = hexToBytes(bjjSwap);

  var sum = 0;
  for (var i = 0; i < bjjSwapBuffer.length; i++) {
    sum += bjjSwapBuffer[i];
    sum = sum % pow(2, 8);
  }

  final BytesBuilder finalBuffBjj = BytesBuilder();
  finalBuffBjj.add(bjjSwapBuffer.toList());
  finalBuffBjj.addByte(sum);

  return 'hez:${base64Url.encode(finalBuffBjj.toBytes())}';
}
