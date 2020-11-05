import 'dart:typed_data';

/// Chunks inputs in five elements and hash with Poseidon all them togheter
/// @param {Array} arr - inputs hash
/// @returns {BigInt} - final hash
BigInt multiHash(List arr) {
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
    //const ph = hash(fiveElems)
    //r = F.add(r, ph);
  }
  //return F.normalize(r);
}

/// Converts an amount in BigInt and decimals to a String with correct decimal point placement
///
/// @param {String} amountBigInt - String representing the amount as a BigInt with no decimals
/// @param {Number} decimals - Number of decimal points the amount actually has
///
/// @returns {String}
String getTokenAmountString(amountBigInt, decimals) {
  //return ethers.utils.formatUnits(amountBigInt, decimals)
}

Uint8List getUint8ListFromString(String source) {
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