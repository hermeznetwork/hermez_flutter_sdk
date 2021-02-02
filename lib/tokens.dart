import 'package:hermez_plugin/utils/contract_parser.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import 'constants.dart';

ContractFunction _approve(DeployedContract contract) =>
    contract.function('approve');
ContractFunction _allowance(DeployedContract contract) =>
    contract.function('allowance');

/// Sends an approve transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param {BigInt} amount - Amount of tokens to be approved by the ERC 20 contract
/// @param {String} accountAddress - The Ethereum address of the transaction sender
/// @param {String} contractAddress - The token smart contract address
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
///
/// @returns {Promise} transaction
Future<bool> approve(
    BigInt amount,
    String accountAddress,
    String tokenContractAddress,
    String tokenContractName,
    Web3Client web3client) async {
  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress, tokenContractName);

  try {
    final allowanceCall = await web3client
        .call(contract: contract, function: _allowance(contract), params: [
      EthereumAddress.fromHex(accountAddress),
      EthereumAddress.fromHex(contractAddresses['Hermez'])
    ]);
    final allowance = allowanceCall.first as BigInt;

    if (allowance < amount) {
      var response = await web3client.call(
        contract: contract,
        function: _approve(contract),
        params: [EthereumAddress.fromHex(contractAddresses['Hermez']), amount],
      );

      return response.first as bool;
    }

    if (!(allowance.sign == 0)) {
      var response = await web3client.call(
        contract: contract,
        function: _approve(contract),
        params: [EthereumAddress.fromHex(contractAddresses['Hermez']), 0],
      );
      return response.first as bool;
    }

    var response = await web3client.call(
      contract: contract,
      function: _approve(contract),
      params: [EthereumAddress.fromHex(accountAddress), amount],
    );

    return response.first as bool;
  } catch (error, trace) {
    print(error);
    print(trace);
  }
}
