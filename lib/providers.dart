import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

Web3Client provider;

/// Set a Provider URL
///
/// @param {String} url - Network url (i.e, http://localhost:8545)
void setProvider(String url, String rdp) {
  provider = Web3Client(url, Client(), socketConnector: () {
    return IOWebSocketChannel.connect(rdp).cast<String>();
  });
}

/// Retrieve provider
///
/// @returns {Object} provider
Web3Client getProvider(String url, String rdp) {
  if (provider == null) {
    setProvider(url, rdp);
  }
  return provider;
}
