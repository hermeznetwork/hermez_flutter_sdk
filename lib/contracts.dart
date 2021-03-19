import 'package:web3dart/web3dart.dart';

import 'providers.dart' show getProvider;

Map<String, dynamic> contractsCache = new Map<String, dynamic>();

/// Caches smart contract instances
///
/// @param {String} contractAddress - The smart contract address
/// @param {Array} abi - The smart contract ABI
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send any deployment transaction
/// @return {ethers.Contract} The request contract
dynamic getContract(
  String contractAddress,
  dynamic abi,
  String providerUrl,
  dynamic signerData,
) {
  final dynamic signerId = signerData.addressOrIndex || signerData.path;
  if (contractsCache.containsKey(contractAddress)) {
    return contractsCache[contractAddress + signerId];
  }
  Web3Client provider = getProvider(providerUrl, providerUrl);
  //final signer = getSigner(provider, signerData);
//ContractAbi.fromJson(abi, '');
  DeployedContract contract =
      new DeployedContract(abi, EthereumAddress.fromHex(contractAddress));

  contractsCache[contractAddress + signerId] = contract;
  return contract;
}
