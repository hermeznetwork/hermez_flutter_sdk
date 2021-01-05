import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

Web3Client provider;

/// Set a Provider URL
///
/// @param {String} url - Network url (i.e, http://localhost:8545)
void setProvider(String url) {
  provider = Web3Client(url, Client());
/*, socketConnector: () {
      return IOWebSocketChannel.connect(params.web3RdpUrl).cast<String>();
    });*/
}

/// Retrieve provider
///
/// @returns {Object} provider
Web3Client getProvider(String url) {
  if (provider == null) {
    setProvider(url);
  }
  return provider;
}
