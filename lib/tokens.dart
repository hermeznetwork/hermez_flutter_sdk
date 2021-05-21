import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_plugin/utils/contract_parser.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import 'constants.dart';
import 'environment.dart';

ContractFunction _approve(DeployedContract contract) =>
    contract.function('approve');
ContractFunction _allowance(DeployedContract contract) =>
    contract.function('allowance');
ContractFunction _transfer(DeployedContract contract) =>
    contract.function('transfer');

/// Sends an approve transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param {BigInt} amount - Amount of tokens to be approved by the ERC 20 contract
/// @param {String} accountAddress - The Ethereum address of the transaction sender
/// @param {String} contractAddress - The token smart contract address
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
///
/// @returns {Promise} transaction
Future<BigInt> approveGasLimit(
    BigInt amount,
    String accountAddress,
    String tokenContractAddress,
    String tokenContractName,
    Web3Client web3client) async {
  BigInt gasLimit = BigInt.zero;
  EthereumAddress from = EthereumAddress.fromHex(accountAddress);
  EthereumAddress to = EthereumAddress.fromHex(tokenContractAddress);
  EthereumAddress hermezAddress =
      EthereumAddress.fromHex(getCurrentEnvironment().contracts['Hermez']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress, tokenContractName);

  try {
    final allowanceCall = await web3client.call(
        contract: contract,
        function: _allowance(contract),
        params: [from, hermezAddress]);
    final allowance = allowanceCall.first as BigInt;

    if (allowance < amount) {
      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: [
          hermezAddress,
          amount,
        ],
      );
      data = transaction.data;
      gasLimit = await web3client.estimateGas(
          sender: from, to: to, value: value, data: data);
      gasLimit += BigInt.from(GAS_LIMIT_APPROVE_OFFSET);
      return gasLimit;
    } else {
      return gasLimit;
    }
  } catch (error, trace) {
    print(error);
    print(trace);
    gasLimit = BigInt.from(GAS_LIMIT_APPROVE_DEFAULT);
    gasLimit += BigInt.from(GAS_LIMIT_APPROVE_OFFSET);
    return gasLimit;
  }
}

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
    Web3Client web3client,
    Credentials credentials,
    {BigInt gasLimit,
    int gasPrice}) async {
  EtherAmount ethGasPrice;
  if (gasLimit == null) {
    gasLimit = BigInt.from(GAS_LIMIT_HIGH);
  }
  if (gasPrice == null) {
    ethGasPrice = await web3client.getGasPrice();
  } else {
    ethGasPrice = EtherAmount.fromUnitAndValue(EtherUnit.wei, gasPrice);
  }

  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress, tokenContractName);

  EthereumAddress ethereumAddress = await credentials.extractAddress();

  try {
    final allowanceCall = await web3client
        .call(contract: contract, function: _allowance(contract), params: [
      EthereumAddress.fromHex(accountAddress),
      EthereumAddress.fromHex(getCurrentEnvironment().contracts['Hermez'])
    ]);
    final allowance = allowanceCall.first as BigInt;

    if (allowance < amount) {
      final transactionParameters = [
        EthereumAddress.fromHex(getCurrentEnvironment().contracts['Hermez']),
        amount
      ];

      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: transactionParameters,
        maxGas: gasLimit.toInt(),
        gasPrice: ethGasPrice,
      );

      String txHash = await web3client.sendTransaction(credentials, transaction,
          chainId: getCurrentEnvironment().chainId);

      print(txHash);

      return txHash != null;
    } else {
      return true;
    }
  } catch (error, trace) {
    print(error);
    print(trace);
  }
}

/// Calculates the gas limit for a transfer transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param {BigInt} amount - Amount of tokens to be transferred by the ERC 20 contract
/// @param {String} accountAddress - The Ethereum address of the transaction sender
/// @param {String} tokenContractAddress - The token smart contract address
/// @param {String} tokenContractName - The token smart contract name
/// @param {Web3Client} web3client - Web3 Client
///
/// @returns {BigInt}
Future<BigInt> transferGasLimit(
    BigInt amount,
    String fromAddress,
    String toAddress,
    String tokenContractAddress,
    String tokenContractName,
    Web3Client web3client) async {

  BigInt gasLimit = BigInt.zero;
  if (fromAddress == null || fromAddress.isEmpty || toAddress == null || toAddress.isEmpty || amount.sign == 0) {
    gasLimit = BigInt.from(GAS_STANDARD_ERC20_TX);
    gasLimit = BigInt.from((gasLimit.toInt() / pow(10, 3)).floor() * pow(10, 3));
    print('estimate transfer default ERC20 --> Max Gas: $gasLimit');
    return gasLimit;
  } else {
    try {
      EthereumAddress from = EthereumAddress.fromHex(fromAddress);
      EthereumAddress to = EthereumAddress.fromHex(toAddress);
      EtherAmount value = EtherAmount.zero();
      Uint8List data;

      final contract = await ContractParser.fromAssets(
          'ERC20ABI.json', tokenContractAddress.toString(), tokenContractName);

      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _transfer(contract),
        parameters: [to, amount],
        from: from,
      );

      data = transaction.data;


      gasLimit = await web3client.estimateGas(
          sender: from, to: to, value: value, data: data);
      print('estimate transfer ERC20 --> Max Gas: $gasLimit');
    } catch (e) {
      print(e.toString());
      gasLimit = BigInt.from(GAS_STANDARD_ERC20_TX);
      print('estimate transfer default ERC20 --> Max Gas: $gasLimit');
    }

    gasLimit += BigInt.from(GAS_STANDARD_ERC20_TX_OFFSET);

    gasLimit =
        BigInt.from((gasLimit.toInt() / pow(10, 3)).floor() * pow(10, 3));

    return gasLimit;
  }
}

/// Sends an transfer transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param {BigInt} amount - Amount of tokens to be approved by the ERC 20 contract
/// @param {String} accountAddress - The Ethereum address of the transaction sender
/// @param {String} tokenContractAddress - The token smart contract address
/// @param {String} tokenContractName - The token smart contract name
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
///
/// @returns {Promise} transaction
Future<bool> transfer(
    BigInt amount,
    String fromAddress,
    String toAddress,
    String tokenContractAddress,
    String tokenContractName,
    Web3Client web3client,
    Credentials credentials,
    {gasLimit = GAS_LIMIT_HIGH,
    gasPrice = GAS_MULTIPLIER}
/*{TransferEvent onTransfer,
    Function onError}*/
    ) async {
  EthereumAddress from = EthereumAddress.fromHex(fromAddress);
  EthereumAddress to = EthereumAddress.fromHex(toAddress);

  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress.toString(), tokenContractName);

  /*StreamSubscription event;
  // Workaround once sendTransacton doesn't return a Promise containing confirmation / receipt
  if (onTransfer != null) {
    event = listenTransfer(
      (from, to, value) async {
        onTransfer(from, to, value);
        await event.cancel();
      },
      contract,
      take: 1,
    );
  }*/

  try {
    Transaction transaction = Transaction.callContract(
      contract: contract,
      function: _transfer(contract),
      parameters: [to, amount],
      from: from,
    );
    String txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
    print(txHash);
    return txHash != null;
  } catch (ex) {
    /*if (onError != null) {
      onError(ex);
    }
    return null;*/
  }
}
