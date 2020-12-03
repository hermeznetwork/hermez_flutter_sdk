const String hermezPrefix = 'hez:';
final hezEthereumAddressPattern = new RegExp('^hez:0x[a-fA-F0-9]{40}\$'); //
final bjjAddressPattern = new RegExp('^hez:[A-Za-z0-9_-]{44}\$');

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
