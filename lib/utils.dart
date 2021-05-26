import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_plugin/utils/uint8_list_utils.dart';

/*final hash = eddsaBabyJub
    .hashPoseidon(Uint8ArrayUtils.toPointer(Uint8List.fromList([6, 8, 57])));*/
//final F =

/// Converts a buffer to a hexadecimal representation
///
/// @param {Uint8List} buf
///
/// @returns {String}
String bufToHex(Uint8List buf) {
  return Utf8Decoder().convert(buf);
}

/*Uint8List hexToBuffer(String hexString) {
  return utf8.encode(hexString);
}*/

/// Chunks inputs in five elements and hash with Poseidon all them togheter
/// @param {Array} arr - inputs hash
/// @returns {BigInt} - final hash
BigInt multiHash(List<BigInt> arr) {
  BigInt r = BigInt.zero;
  for (int i = 0; i < arr.length; i += 5) {
    const fiveElems = [];
    for (int j = 0; j < 5; j++) {
      if (i + j < arr.length) {
        fiveElems.add(arr[i + j]);
      } else {
        fiveElems.add(BigInt.zero);
      }
    }
    Pointer<Uint8> ptr =
        Uint8ArrayUtils.toPointer(Uint8List.fromList(fiveElems));
    //final ph = eddsaBabyJub.hashPoseidon(ptr);
    //r = F.add(r, ph);
  }
  //return F.normalize(r);
}

/// Poseidon hash of a generic buffer
/// @param {Uint8List} msgBuff
/// @returns {BigInt} - final hash
BigInt hashBuffer(Uint8List msgBuff) {
  const n = 31;
  const msgArray = [];
  final fullParts = (msgBuff.length / n).floor();
  for (int i = 0; i < fullParts; i++) {
    final v = msgBuff.sublist(n * i, n * (i + 1)).toList();
    msgArray.addAll(v);
  }
  if (msgBuff.length % n != 0) {
    final v = msgBuff.sublist(fullParts * n).toList();
    msgArray.addAll(v);
  }
  return multiHash(msgArray);
}

/// Converts an amount in BigInt and decimals to a String with correct decimal point placement
///
/// @param {String} amountBigInt - String representing the amount as a BigInt with no decimals
/// @param {Number} decimals - Number of decimal points the amount actually has
///
/// @returns {String}
String getTokenAmountString(String amountBigInt, int decimals) {
  return (BigInt.parse(amountBigInt) / BigInt.from(10).pow(decimals))
      .toStringAsFixed(decimals);
  //return ethers.utils.formatUnits(amountBigInt, decimals);
}

/// Converts an amount in double with the appropriate decimals to a BigInt
/// @param {double} amount - representing the amount as a double
/// @param {int} decimals - Number of decimal points the amount has
/// @returns {BigInt}
BigInt getTokenAmountBigInt(double amount, int decimals) {
  double tokenAmount = amount * pow(10, decimals);
  return BigInt.from(tokenAmount);
}

Uint8List hexToBuffer(String source) {
  // Source
  print(source.length.toString() +
      ': "' +
      source +
      '" (' +
      source.runes.length.toString() +
      ')');

  // String (Dart uses UTF-16) to bytes
  var list = new List<int>();
  source.runes.forEach((rune) {
    if (rune >= 0x10000) {
      rune -= 0x10000;
      int firstWord = (rune >> 10) + 0xD800;
      list.add(firstWord >> 8);
      list.add(firstWord & 0xFF);
      int secondWord = (rune & 0x3FF) + 0xDC00;
      list.add(secondWord >> 8);
      list.add(secondWord & 0xFF);
    } else {
      list.add(rune >> 8);
      list.add(rune & 0xFF);
    }
  });
  Uint8List bytes = Uint8List.fromList(list);
  return bytes;
}
