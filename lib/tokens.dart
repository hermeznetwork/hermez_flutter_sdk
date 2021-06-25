import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_sdk/utils/contract_parser.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import 'constants.dart';
import 'environment.dart';
import 'hermez_sdk.dart';

ContractFunction _approve(DeployedContract contract) =>
    contract.function('approve');
ContractFunction _allowance(DeployedContract contract) =>
    contract.function('allowance');
ContractFunction _transfer(DeployedContract contract) =>
    contract.function('transfer');

/// Calculates the gas limit of an approve transaction to an ERC 20 contract
/// for a certain amount of tokens
///
/// @param [BigInt] amount - Amount of tokens to be approved by the ERC 20 contract
/// @param [String] accountAddress - The Ethereum address of the transaction sender
/// @param [String] tokenContractAddress - The token smart contract address
/// @param [String] tokenContractName - The token smart contract name
///
/// @returns [BigInt] transaction gas limit
Future<BigInt> approveGasLimit(BigInt amount, String accountAddress,
    String tokenContractAddress, String tokenContractName) async {
  BigInt gasLimit = BigInt.zero;
  EthereumAddress from = EthereumAddress.fromHex(accountAddress);
  EthereumAddress to = EthereumAddress.fromHex(tokenContractAddress);
  EthereumAddress hermezAddress = EthereumAddress.fromHex(
      getCurrentEnvironment()!.contracts[ContractName.hermez]!);
  EtherAmount value = EtherAmount.zero();
  Uint8List? data;

  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress, tokenContractName);

  try {
    final allowanceCall = await HermezSDK.currentWeb3Client!.call(
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
      gasLimit = await HermezSDK.currentWeb3Client!
          .estimateGas(sender: from, to: to, value: value, data: data);
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

/// Sends an approve transaction to an ERC20 contract for a certain amount of tokens
///
/// @param [BigInt] amount - Amount of tokens to be approved by the ERC 20 contract
/// @param [String] accountAddress - The Ethereum address of the transaction sender
/// @param [String] tokenContractAddress - The token smart contract address
/// @param [String] tokenContractName - The token smart contract name
/// @param [String] privateKey - Ethereum private key used to send the transaction
/// @param optional [BigInt] gasLimit - Gas limit set for sending the transaction
/// @param optional [int] gasPrice - Gas price set for sending the transaction
///
/// @returns [bool] true if there is enough amount of tokens approved
Future<bool> approve(BigInt amount, String accountAddress,
    String tokenContractAddress, String tokenContractName, String privateKey,
    {BigInt? gasLimit, int? gasPrice}) async {
  EtherAmount ethGasPrice;
  if (gasLimit == null) {
    gasLimit = BigInt.from(GAS_LIMIT_HIGH);
  }
  if (gasPrice == null) {
    ethGasPrice = await HermezSDK.currentWeb3Client!.getGasPrice();
  } else {
    ethGasPrice = EtherAmount.fromUnitAndValue(EtherUnit.wei, gasPrice);
  }

  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress, tokenContractName);

  final credentials =
      await HermezSDK.currentWeb3Client!.credentialsFromPrivateKey(privateKey);
  EthereumAddress from = await credentials.extractAddress();

  try {
    final allowanceCall = await HermezSDK.currentWeb3Client!
        .call(contract: contract, function: _allowance(contract), params: [
      EthereumAddress.fromHex(accountAddress),
      EthereumAddress.fromHex(getCurrentEnvironment()!.contracts['Hermez']!)
    ]);
    final allowance = allowanceCall.first as BigInt;

    if (allowance < amount) {
      final transactionParameters = [
        EthereumAddress.fromHex(getCurrentEnvironment()!.contracts['Hermez']!),
        amount
      ];

      int nonce = await HermezSDK.currentWeb3Client!
          .getTransactionCount(from, atBlock: BlockNum.pending());

      Transaction transaction = Transaction.callContract(
        contract: contract,
        function: _approve(contract),
        parameters: transactionParameters,
        maxGas: gasLimit.toInt(),
        gasPrice: ethGasPrice,
        nonce: nonce,
      );

      String txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
          credentials, transaction,
          chainId: getCurrentEnvironment()!.chainId);

      print(txHash);
    }
    return true;
  } catch (error, trace) {
    print(error);
    print(trace);
    return false;
  }
}

/// Calculates the gas limit for a transfer transaction to an ERC 20 contract
/// for a certain amount of tokens
///
/// @param [BigInt] amount - Amount of tokens to be transferred by the ERC 20 contract
/// @param [String] fromAddress - The Ethereum address of the transaction sender
/// @param [String] toAddress - The Ethereum address of the transaction receiver
/// @param [String] tokenContractAddress - The token smart contract address
/// @param [String] tokenContractName - The token smart contract name
///
/// @returns [BigInt] transaction gas limit
Future<BigInt> transferGasLimit(
    BigInt amount,
    String fromAddress,
    String toAddress,
    String tokenContractAddress,
    String tokenContractName) async {
  BigInt gasLimit = BigInt.zero;
  if (fromAddress.isEmpty || toAddress.isEmpty || amount.sign == 0) {
    gasLimit = BigInt.from(GAS_STANDARD_ERC20_TX);
    gasLimit =
        BigInt.from((gasLimit.toInt() / pow(10, 3)).floor() * pow(10, 3));
    print('estimate transfer default ERC20 --> Max Gas: $gasLimit');
    return gasLimit;
  } else {
    // TODO: Uncomment when estimation is working well
    /*try {
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
      print(e.toString());*/
    gasLimit = BigInt.from(GAS_STANDARD_ERC20_TX);
    print('estimate transfer default ERC20 --> Max Gas: $gasLimit');
    //}

    gasLimit =
        BigInt.from((gasLimit.toInt() / pow(10, 3)).floor() * pow(10, 3));

    return gasLimit;
  }
}

/// Sends an transfer transaction to an ERC 20 contract for a certain amount of tokens
///
/// @param [BigInt] amount - Amount of tokens to be transferred by the ERC 20 contract
/// @param [String] fromAddress - The Ethereum address of the transaction sender
/// @param [String] toAddress - The Ethereum address of the transaction receiver
/// @param [String] tokenContractAddress - The token smart contract address
/// @param [String] tokenContractName - The token smart contract name
/// @param [String] privateKey - Ethereum private key used to send the transaction
/// @param optional [BigInt] gasLimit - Gas limit set for sending the transaction
/// @param optional [int] gasPrice - Gas price set for sending the transaction
///
/// @returns [String] transaction hash
Future<String?> transfer(BigInt amount, String fromAddress, String toAddress,
    String tokenContractAddress, String tokenContractName, String privateKey,
    {BigInt? gasLimit, int gasPrice = 0}) async {
  if (gasLimit == null) {
    gasLimit = BigInt.from(GAS_LIMIT_HIGH);
  }
  EtherAmount ethGasPrice;
  if (gasPrice > 0) {
    ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));
  } else {
    ethGasPrice = await HermezSDK.currentWeb3Client!.getGasPrice();
  }

  EthereumAddress from = EthereumAddress.fromHex(fromAddress);
  EthereumAddress to = EthereumAddress.fromHex(toAddress);

  final contract = await ContractParser.fromAssets(
      'ERC20ABI.json', tokenContractAddress.toString(), tokenContractName);

  int nonce = await HermezSDK.currentWeb3Client!
      .getTransactionCount(from, atBlock: BlockNum.pending());

  try {
    Transaction transaction = Transaction.callContract(
      contract: contract,
      function: _transfer(contract),
      parameters: [to, amount],
      from: from,
      maxGas: gasLimit.toInt(),
      gasPrice: ethGasPrice,
      nonce: nonce,
    );

    final credentials = await HermezSDK.currentWeb3Client!
        .credentialsFromPrivateKey(privateKey);

    String txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment()!.chainId);
    print(txHash);
    return txHash;
  } catch (e) {
    print(e.toString());
    return null;
  }
}
