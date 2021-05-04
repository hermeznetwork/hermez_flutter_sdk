import 'package:hermez_plugin/utils/contract_parser.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import 'constants.dart';
import 'environment.dart';

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
    num amount,
    String accountAddress,
    String tokenContractAddress,
    String tokenContractName,
    Web3Client web3client,
    Credentials credentials) async {
  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress, tokenContractName);

  EthereumAddress ethereumAddress = await credentials.extractAddress();

  try {
    final allowanceCall = await web3client
        .call(contract: contract, function: _allowance(contract), params: [
      EthereumAddress.fromHex(accountAddress),
      EthereumAddress.fromHex(contractAddresses['Hermez'])
    ]);
    final allowance = allowanceCall.first as BigInt;

    if (allowance.toInt() < amount) {
      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: [
          EthereumAddress.fromHex(contractAddresses['Hermez']),
          BigInt.from(amount)
        ],
      );

      String txHash = await web3client.sendTransaction(credentials, transaction,
          chainId: getCurrentEnvironment().chainId);

      print(txHash);

      return txHash != null;
    }

    if (!(allowance.sign == 0)) {
      String txHash = await web3client.sendTransaction(
          credentials,
          Transaction.callContract(
              contract: contract,
              function: _approve(contract),
              parameters: [
                EthereumAddress.fromHex(contractAddresses['Hermez']),
                BigInt.zero
              ]),
          chainId: getCurrentEnvironment().chainId);

      print(txHash);
    }

    final transactionParameters = [
      EthereumAddress.fromHex(contractAddresses['Hermez']),
      BigInt.from(amount)
    ];

    int nonce = await web3client.getTransactionCount(ethereumAddress);

    Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: transactionParameters,
        nonce: nonce++);

    String txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);

    print(txHash);

    return txHash != null;
  } catch (error, trace) {
    print(error);
    print(trace);
  }
}
