import 'api.dart' as coordinatorApi;

EnvParams? params = Env(web3ApiKey: '').params['rinkeby'];

class Env {
  Env({required String web3ApiKey}) {
    params['mainnet'] = EnvParams(
        1,
        {
          ContractName.hermez:
              "0xA68D85dF56E733A06443306A095646317B5Fa633", // Hermez
          ContractName.withdrawalDelayer:
              "0x392361427Ef5e17b69cFDd1294F31ab555c86124", // WithdrawalDelayer
        },
        "api.hermez.io",
        "https://explorer.hermez.io",
        "https://mainnet.infura.io/v3/" + web3ApiKey,
        "wss://mainnet.infura.io/v3/" + web3ApiKey);

    params['rinkeby'] = EnvParams(
        4,
        {
          ContractName.hermez:
              "0x679b11E0229959C1D3D27C9d20529E4C5DF7997c", // Hermez
          ContractName.withdrawalDelayer:
              "0xeFD96CFBaF1B0Dd24d3882B0D6b8D95F85634724", // WithdrawalDelayer
        },
        "api.testnet.hermez.io",
        "https://explorer.testnet.hermez.io",
        "https://rinkeby.infura.io/v3/" + web3ApiKey,
        "wss://rinkeby.infura.io/v3/" + web3ApiKey);

    params['goerli'] = EnvParams(
        5,
        {
          ContractName.hermez:
              "0xf08a226B67a8A9f99cCfCF51c50867bc18a54F53", // Hermez
          ContractName.withdrawalDelayer:
              "0xC6570883Cc7e95d12Bc2BE6821570cB6433e3ece" // WithdrawalDelayer
        },
        "api.internaltestnet.hermez.io",
        "https://explorer.internaltestnet.hermez.io",
        "https://goerli.infura.io/v3/" + web3ApiKey,
        "wss://goerli.infura.io/v3/" + web3ApiKey);

    /*params['local'] = EnvParams(
      1337,
      {
        ContractName.hermez:
            "0x10465b16615ae36F350268eb951d7B0187141D3B", // Hermez
        ContractName.withdrawalDelayer:
            "0x8EEaea23686c319133a7cC110b840d1591d9AeE0" // WithdrawalDelayer
      },
      "192.168.250.101:8086",
      "192.168.250.101:8080",
      'http://192.168.250.101:8545',
      'wss://192.168.250.101:8545',
    );*/
  }

  Map<String, EnvParams> params = Map<String, EnvParams>();

  static final Set<String> supportedEnvironments = {
    "mainnet",
    "rinkeby",
    "goerli",
    //"local",
    "custom"
  };
}

class EnvParams {
  EnvParams(
    this.chainId,
    this.contracts,
    this.baseApiUrl,
    this.batchExplorerUrl,
    this.baseWeb3Url,
    this.baseWeb3RdpUrl,
  );
  final int chainId;
  final Map<String, String> contracts;
  final String baseApiUrl;
  final String batchExplorerUrl;
  final String baseWeb3Url;
  final String baseWeb3RdpUrl;
}

class ContractName {
  static String get hermez {
    return 'Hermez';
  }

  static String get withdrawalDelayer {
    return 'WithdrawalDelayer';
  }
}

/// Gets the current supported environments
/// @returns {Object[]} Supported environments
Set<String> getSupportedEnvironments() {
  return Env.supportedEnvironments;
}

/// Sets an environment from a supported environment configuration or from a custom environment object
/// @param {String} env - Supported environment name
/// @param {String} web3ApiKey - Web3 api key
/// @param optional {EnvParams} envParams - Custom environment object, only used when env value is 'custom'
void setEnvironment(String env, String? web3ApiKey, {EnvParams? envParams}) {
  if (env == null) {
    throw new ArgumentError('A environment is required');
  }

  if (env != 'custom' && (web3ApiKey == null || web3ApiKey.isEmpty)) {
    throw new ArgumentError('A web3 api key is required');
  }

  if (!getSupportedEnvironments().contains(env)) {
    throw new ArgumentError('Environment not supported');
  }

  if (env == 'custom' && envParams != null) {
    params = envParams;
  } else {
    params = Env(web3ApiKey: web3ApiKey!).params[env];
  }

  coordinatorApi.setBaseApiUrl(params!.baseApiUrl);
}

/// Returns the current environment
/// @returns {Object} Contains contract addresses, Hermez API and Batch Explorer urls
/// and the Etherscan URL por the provider
EnvParams? getCurrentEnvironment() {
  return params;
}
