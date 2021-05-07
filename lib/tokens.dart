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
Future<List<BigInt>> approveGasLimit(
    BigInt amount,
    String accountAddress,
    String tokenContractAddress,
    String tokenContractName,
    Web3Client web3client) async {
  List<BigInt> result = [];
  BigInt gasLimit = BigInt.zero;
  EthereumAddress from = EthereumAddress.fromHex(accountAddress);
  EthereumAddress to = EthereumAddress.fromHex(tokenContractAddress);
  EthereumAddress hermezAddress =
      EthereumAddress.fromHex(contractAddresses['Hermez']);
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
      result.add(gasLimit);
      return result;
    }

    if (!(allowance.sign == 0)) {
      final transactionParameters = [
        hermezAddress,
        BigInt.zero,
      ];
      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: transactionParameters,
      );
      data = transaction.data;
      gasLimit = await web3client.estimateGas(
          sender: from, to: to, value: value, data: data);
      result.add(gasLimit);
    }

    final transactionParameters = [
      hermezAddress,
      amount,
    ];
    Transaction transaction = Transaction.callContract(
      contract: contract,
      function: _approve(contract),
      parameters: transactionParameters,
    );
    data = transaction.data;
    gasLimit = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
    result.add(gasLimit);
    return result;
  } catch (error, trace) {
    print(error);
    print(trace);
    // TODO: default approve gas limit
    result.add(gasLimit);
    return result;
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
    {List<BigInt> gasLimit,
    gasPrice = GAS_MULTIPLIER}) async {
  if (gasLimit == null) {
    gasLimit = [BigInt.from(GAS_LIMIT_HIGH)];
  }
  int gasLimitPosition = 0;
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

    if (allowance < amount) {
      final transactionParameters = [
        EthereumAddress.fromHex(contractAddresses['Hermez']),
        amount
      ];

      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: transactionParameters,
        maxGas: gasLimit[gasLimitPosition].toInt(),
        gasPrice: gasPrice,
      );

      String txHash = await web3client.sendTransaction(credentials, transaction,
          chainId: getCurrentEnvironment().chainId);

      print(txHash);

      return txHash != null;
    }

    if (!(allowance.sign == 0)) {
      final transactionParameters = [
        EthereumAddress.fromHex(contractAddresses['Hermez']),
        BigInt.zero
      ];
      Transaction transaction = Transaction.callContract(
          contract: contract,
          function: _approve(contract),
          parameters: transactionParameters,
          maxGas: gasLimit[gasLimitPosition].toInt(),
          gasPrice: gasPrice);

      String txHash = await web3client.sendTransaction(credentials, transaction,
          chainId: getCurrentEnvironment().chainId);

      print(txHash);

      if (txHash != null) {
        gasLimitPosition += 1;
      }
    }

    final transactionParameters = [
      EthereumAddress.fromHex(contractAddresses['Hermez']),
      amount
    ];

    int nonce = await web3client.getTransactionCount(ethereumAddress);

    Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: transactionParameters,
        maxGas: gasLimit[gasLimitPosition].toInt(),
        gasPrice: gasPrice,
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

  try {
    gasLimit = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
  } catch (e) {
    gasLimit = BigInt.from(GAS_STANDARD_ERC20_TX);
  }

  print('estimate transfer ERC20 --> Max Gas: $gasLimit');
  return gasLimit;
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
