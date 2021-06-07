import 'package:hermez_sdk/environment.dart';
import 'package:hermez_sdk/model/token.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class HermezSDK {
  static Web3Client _web3Client;
  static EnvParams _environment;

  /// Sets an environment from a supported environment configuration or from a custom environment object
  /// @param {String} env - Supported environment name
  /// @param optional {EnvParams} envParams - Custom environment object, only used when env value is 'custom'
  static void init(String environment,
      {String web3ApiKey, EnvParams envParams}) {
    // setup environment
    setEnvironment(environment, web3ApiKey, envParams: envParams);
    _environment = getCurrentEnvironment();

    // setup web3 client
    _web3Client = Web3Client(getCurrentEnvironment().baseWeb3Url, Client(),
        enableBackgroundIsolate: true, socketConnector: () {
      return IOWebSocketChannel.connect(getCurrentEnvironment().baseWeb3RdpUrl)
          .cast<String>();
    });
  }

  static bool get isInitialized {
    return _web3Client != null && _environment != null;
  }

  /// Returns the current web3 client
  /// @returns {Object} Contains contract addresses, Hermez API and Batch Explorer urls
  /// and the Etherscan URL por the provider
  static Web3Client get currentWeb3Client {
    return _web3Client;
  }

  /// Returns the current environment
  /// @returns {EnvParams} Contains contract addresses, Hermez API and Batch Explorer urls
  static EnvParams get currentEnvironment {
    return _environment;
  }

  static List<Token> get supportedTokens {}
}
