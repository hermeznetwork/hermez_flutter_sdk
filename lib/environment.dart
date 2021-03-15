import 'api.dart' as coordinatorApi;
import 'constants.dart' as constants;

EnvParams params = Env().params['local'];

class Env {
  Env() {
    params['local'] = EnvParams(
        1337,
        {
          "0x10465b16615ae36F350268eb951d7B0187141D3B", // Hermez
          "0x8EEaea23686c319133a7cC110b840d1591d9AeE0" // WithdrawalDelayer
        },
        //"192.168.1.134:8086",
        //'192.168.1.134:8545',
        //"192.168.1.134:8080",
        "192.168.250.101:8086",
        'http://192.168.250.101:8545',
        'wss://192.168.250.101:8545',
        "192.168.250.101:8080",
        "https://etherscan.io");

    params['rinkeby'] = EnvParams(
        4,
        {
          "0x14A3B6f3328766c7421034e14472F5c14C5Ba090", // Hermez
          "0x6eA0aBF3EF52D24427043cAd3ec26Aa4f2c8E8fd", // WithdrawalDelayer
        },
        "api.testnet.hermez.io",
        "https://rinkeby.infura.io/v3/80596e41f0a148ccbc9a856abd054696",
        "wss://rinkeby.infura.io/v3/80596e41f0a148ccbc9a856abd054696",
        "http://explorer.testnet.hermez.io",
        "https://rinkeby.etherscan.io");
  }

  Map<String, EnvParams> params = Map<String, EnvParams>();

  static final Set<String> supportedEnvironments = {
    "local",
    "rinkeby",
  };
}

class EnvParams {
  EnvParams(this.chainId, this.contracts, this.baseApiUrl, this.baseWeb3Url,
      this.baseWeb3RdpUrl, this.batchExplorerUrl, this.etherscanUrl);
  final int chainId;
  final Set<String> contracts;
  final String baseApiUrl;
  final String baseWeb3Url;
  final String baseWeb3RdpUrl;
  final String batchExplorerUrl;
  final String etherscanUrl;
}

/// Gets the current supported environments
/// @returns {Object[]} Supported environments
Set<String> getSupportedEnvironments() {
  return Env.supportedEnvironments;
}

/// Sets an environment from a chain id or from a custom environment object
/// @param {Object|Number} env - Chain id or a custom environment object
void setEnvironment(String env) {
  if (env == null) {
    throw new ArgumentError('A environment is required');
  }

  if (!getSupportedEnvironments().contains(env)) {
    throw new ArgumentError('Environment not supported');
  }

  params = Env().params[env];
  constants.contractAddresses['Hermez'] = params.contracts.first;
  constants.contractAddresses['WithdrawalDelayer'] = params.contracts.last;
  coordinatorApi.setBaseApiUrl(params.baseApiUrl);
}

/// Returns the current environment
/// @returns {Object} Contains contract addresses, Hermez API and Batch Explorer urls
/// and the Etherscan URL por the provider
EnvParams getCurrentEnvironment() {
  return params;
}
