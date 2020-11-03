import 'package:web3dart/web3dart.dart';

import 'providers.dart' show getProvider;

Map<String, dynamic> contractsCache = new Map<String, dynamic>();

/// Caches smart contract instances
///
/// @param {String} contractAddress - The smart contract address
/// @param {Array} abi - The smart contract ABI
dynamic getContract(String contractAddress, dynamic abi) {
  if (contractsCache.containsKey(contractAddress)) {
    return contractsCache[contractAddress];
  }
  Web3Client provider = getProvider();
//ContractAbi.fromJson(abi, '');
  DeployedContract contract =
      new DeployedContract(abi, EthereumAddress.fromHex(contractAddress));

  contractsCache[contractAddress] = contract;
  return contract;
}
