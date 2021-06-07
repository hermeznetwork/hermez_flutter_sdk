import 'package:hermez_plugin/hermez_sdk.dart';
import 'package:web3dart/web3dart.dart';

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
  Web3Client provider = HermezSDK.currentWeb3Client;
  //final signer = getSigner(provider, signerData);
//ContractAbi.fromJson(abi, '');
  DeployedContract contract =
      new DeployedContract(abi, EthereumAddress.fromHex(contractAddress));

  contractsCache[contractAddress + signerId] = contract;
  return contract;
}

// TODO: abstract this

/*Future readContract(Web3Client web3client, DeployedContract contract,
    ContractFunction functionName, List functionArgs) async {
  var queryResult = await web3client.call(
      contract: contract, function: functionName, params: functionArgs);
  return queryResult;
}

Future writeContract(
  Web3Client web3client,
  Credentials credentials,
  DeployedContract contract,
  ContractFunction functionName,
  List functionArgs,
) async {
  await web3client.sendTransaction(
    credentials,
    Transaction.callContract(
      contract: contract,
      function: functionName,
      parameters: functionArgs,
    ),
  );
}*/
