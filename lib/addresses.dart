const String hermezPrefix = 'hez:';

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
