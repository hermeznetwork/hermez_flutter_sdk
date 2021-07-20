import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_sdk/environment.dart';
import 'package:hermez_sdk/hermez_sdk.dart';
import 'package:hermez_sdk/hermez_wallet.dart';
import 'package:hermez_sdk/model/token.dart';
import 'package:hermez_sdk/tokens.dart';
import 'package:hermez_sdk/utils/contract_parser.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'addresses.dart'
    show getAccountIndex, getEthereumAddress, getHermezAddress;
import 'api.dart' show getAccounts, postPoolTransaction;
import 'constants.dart'
    show
        GAS_LIMIT_DEPOSIT_OFFSET,
        GAS_LIMIT_HIGH,
        GAS_LIMIT_LOW,
        GAS_LIMIT_OFFSET,
        GAS_LIMIT_WITHDRAW_DEFAULT,
        GAS_LIMIT_WITHDRAW_SIBLING;
import 'hermez_compressed_amount.dart';
import 'model/account.dart';
import 'tx_pool.dart' show addPoolTransaction;
import 'tx_utils.dart' show generateL2Transaction;

ContractFunction _addL1Transaction(DeployedContract contract) =>
    contract.function('addL1Transaction');
ContractFunction _withdrawMerkleProof(DeployedContract contract) =>
    contract.function('withdrawMerkleProof');
ContractFunction _withdrawal(DeployedContract contract) =>
    contract.function('withdrawal');
ContractFunction _instantWithdrawalViewer(DeployedContract contract) =>
    contract.function('instantWithdrawalViewer');

/*ContractEvent _addTokenEvent(DeployedContract contract) =>
    contract.event('AddToken');
ContractEvent _l1UserTxEvent(DeployedContract contract) =>
    contract.event('L1UserTxEvent');*/

/// Makes a deposit.
/// It detects if it's a 'createAccountDeposit' or a 'deposit' and prepares the parameters accordingly.
/// Detects if it's an Ether, ERC 20 token and sends the transaction accordingly.
///
/// @param [HermezCompressedAmount] amount - The compressed amount to be deposited
/// @param [String] hezEthereumAddress - The Hermez address of the transaction sender
/// @param [Token] token - The token information object as returned from the API
/// @param [String] babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param [String] privateKey - Ethereum private key used to send the transaction
/// @param optional [BigInt] approveGasLimit - Gas limit set for approving the amount of tokens for the transaction
/// @param optional [BigInt] depositGasLimit - Gas limit set for the deposit transaction
/// @param optional [int] gasPrice - Gas price set for sending the transaction
///
/// @returns {String} transaction hash
Future<String?> deposit(
    HermezCompressedAmount amount,
    String hezEthereumAddress,
    Token token,
    String babyJubJub,
    String privateKey,
    {BigInt? approveMaxGas,
    BigInt? depositMaxGas,
    int gasPrice = 0}) async {
  if (approveMaxGas == null || depositMaxGas == null) {
    LinkedHashMap<String, BigInt> gasLimits =
        await depositGasLimit(amount, hezEthereumAddress, token, babyJubJub);
    if (approveMaxGas == null) {
      approveMaxGas = gasLimits['approveGasLimit'];
    }
    if (depositMaxGas == null) {
      depositMaxGas = gasLimits['depositGasLimit'];
    }
  }

  EtherAmount ethGasPrice;
  if (gasPrice > 0) {
    ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));
  } else {
    ethGasPrice = await HermezSDK.currentWeb3Client!.getGasPrice();
  }

  var accounts;
  try {
    accounts = await getAccounts(hezEthereumAddress, [token.id]);
  } catch (e) {
    accounts = null;
  }
  final Account? account = accounts != null && accounts.accounts!.isNotEmpty
      ? accounts.accounts![0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment()!.contracts[ContractName.hermez]!,
      ContractName.hermez);

  final credentials =
      await HermezSDK.currentWeb3Client!.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  final transactionParameters = [
    account != null ? BigInt.zero : hexToInt(babyJubJub),
    account != null
        ? BigInt.from(getAccountIndex(account.accountIndex))
        : BigInt.zero,
    BigInt.from(amount.value),
    BigInt.zero,
    BigInt.from(token.id),
    BigInt.zero,
    hexToBytes('0x')
  ];

  final decompressedAmount = HermezCompressedAmount.decompressAmount(amount);

  if (token.id == 0) {
    int nonce = await HermezSDK.currentWeb3Client!
        .getTransactionCount(from, atBlock: BlockNum.pending());

    Transaction transaction = Transaction.callContract(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        from: from,
        parameters: transactionParameters,
        maxGas: depositMaxGas!.toInt() - 1000,
        gasPrice: ethGasPrice,
        value: EtherAmount.fromUnitAndValue(
            EtherUnit.wei, BigInt.from(decompressedAmount)),
        nonce: nonce);

    print(
        'deposit ETH --> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address},'
        ' amountInWei: $decompressedAmount, depositGasLimit: ${depositMaxGas.toInt()}, gasPrice: ${ethGasPrice.getInWei}');

    String? txHash;
    try {
      txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
          credentials, transaction,
          chainId: getCurrentEnvironment()!.chainId);

      print(txHash);
      return txHash;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  await approve(BigInt.from(decompressedAmount), from.hex,
      token.ethereumAddress!, token.name!, privateKey,
      gasLimit: approveMaxGas, gasPrice: gasPrice);

  int nonce = await HermezSDK.currentWeb3Client!
      .getTransactionCount(from, atBlock: BlockNum.pending());

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      parameters: transactionParameters,
      maxGas: depositMaxGas!.toInt() - 1000,
      gasPrice: ethGasPrice,
      nonce: nonce);

  print(
      'deposit ERC20--> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address},'
      ' amountInWei: $amount, depositGasLimit: ${depositMaxGas.toInt()}, gasPrice: ${ethGasPrice.getInWei}');

  String? txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment()!.chainId);
    print(txHash);
    return txHash;
  } catch (e) {
    print(e.toString());
    return null;
  }
}

/// Calculates the gas limit for a deposit transaction.
/// It detects if it's a 'createAccountDeposit' or a 'deposit' and prepares the parameters accordingly.
/// Detects if it's an Ether, ERC 20 token and sends the transaction accordingly.
///
/// @param [HermezCompressedAmount] amount - The compressed amount to be deposited
/// @param [String] hezEthereumAddress - The Hermez address of the transaction sender
/// @param [Token] token - The token information object as returned from the API
/// @param [String] babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
///
/// @returns [LinkedHashMap<String, BigInt>] transaction gas limits
Future<LinkedHashMap<String, BigInt>> depositGasLimit(
    HermezCompressedAmount amount,
    String hezEthereumAddress,
    Token token,
    String babyJubJub) async {
  LinkedHashMap<String, BigInt> result = new LinkedHashMap<String, BigInt>();
  BigInt approveMaxGas = BigInt.zero;
  BigInt depositMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(
      getCurrentEnvironment()!.contracts[ContractName.hermez]!);
  EtherAmount value = EtherAmount.zero();
  Uint8List? data;

  final ethereumAddress = getEthereumAddress(hezEthereumAddress);

  var accounts;
  try {
    accounts = await getAccounts(hezEthereumAddress, [token.id]);
  } catch (e) {
    accounts = null;
  }

  final Account? account = accounts != null && accounts.accounts!.isNotEmpty
      ? accounts.accounts![0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment()!.contracts[ContractName.hermez]!,
      ContractName.hermez);

  final transactionParameters = [
    account != null ? BigInt.zero : hexToInt(babyJubJub),
    account != null
        ? BigInt.from(getAccountIndex(account.accountIndex))
        : BigInt.zero,
    BigInt.from(amount.value),
    BigInt.zero,
    BigInt.from(token.id),
    BigInt.zero,
    hexToBytes('0x')
  ];

  final decompressedAmount = HermezCompressedAmount.decompressAmount(amount);

  if (token.id == 0) {
    try {
      value = EtherAmount.fromUnitAndValue(
          EtherUnit.wei, BigInt.from(decompressedAmount));
      Transaction transaction = Transaction.callContract(
          contract: hermezContract,
          function: _addL1Transaction(hermezContract),
          from: from,
          parameters: transactionParameters,
          value: value);
      data = transaction.data;
      depositMaxGas = await HermezSDK.currentWeb3Client!
          .estimateGas(sender: from, to: to, value: value, data: data);
      depositMaxGas += BigInt.from(GAS_LIMIT_DEPOSIT_OFFSET);
    } catch (e) {
      depositMaxGas = BigInt.from(GAS_LIMIT_LOW);
    }

    depositMaxGas =
        BigInt.from((depositMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

    result['depositGasLimit'] = depositMaxGas;

    print('estimate deposit ETH --> Max Gas: $depositMaxGas');

    return result;
  }

  approveMaxGas = await approveGasLimit(BigInt.from(decompressedAmount),
      ethereumAddress, token.ethereumAddress!, token.name!);

  approveMaxGas =
      BigInt.from((approveMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  result['approveGasLimit'] = approveMaxGas;

  try {
    Transaction transaction = Transaction.callContract(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        from: from,
        parameters: transactionParameters,
        value: value);
    data = transaction.data;
    depositMaxGas = await HermezSDK.currentWeb3Client!
        .estimateGas(sender: from, to: to, value: value, data: data);
    depositMaxGas += BigInt.from(GAS_LIMIT_DEPOSIT_OFFSET);
  } catch (e) {
    depositMaxGas = BigInt.from(GAS_LIMIT_HIGH);
    String fromAddress = getCurrentEnvironment()!
        .contracts[ContractName.hermez]!; // Random ethereum address
    depositMaxGas += await transferGasLimit(BigInt.from(decompressedAmount),
        fromAddress, ethereumAddress, token.ethereumAddress!, token.name!);
  }

  depositMaxGas =
      BigInt.from((depositMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  result['depositGasLimit'] = depositMaxGas;

  print('estimate deposit ERC20 --> Max Gas: $depositMaxGas');

  return result;
}

/// Makes a Force Exit. This is the L1 transaction equivalent of Exit.
///
/// @param [HermezCompressedAmount] amount - The compressed amount to be withdrawn
/// @param [String] accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param [Token] token - The token information object as returned from the API
/// @param [String] privateKey - Ethereum private key used to send the transaction
/// @param optional [BigInt] gasLimit - Gas limit set for sending the transaction
/// @param optional [int] gasPrice - Gas price set for sending the transaction
///
/// @returns [String] transaction hash
Future<String?> forceExit(HermezCompressedAmount amount, String accountIndex,
    Token token, String privateKey,
    {BigInt? gasLimit, int gasPrice = 0}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment()!.contracts[ContractName.hermez]!,
      ContractName.hermez);

  final credentials =
      await HermezSDK.currentWeb3Client!.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  if (gasLimit == null) {
    gasLimit = await forceExitGasLimit(
        amount, getHermezAddress(from.hex), accountIndex, token);
  }

  EtherAmount ethGasPrice;
  if (gasPrice > 0) {
    ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));
  } else {
    ethGasPrice = await HermezSDK.currentWeb3Client!.getGasPrice();
  }

  int nonce = await HermezSDK.currentWeb3Client!
      .getTransactionCount(from, atBlock: BlockNum.pending());

  final transactionParameters = [
    BigInt.zero,
    BigInt.from(getAccountIndex(accountIndex)),
    BigInt.zero,
    BigInt.from(amount.value),
    BigInt.from(token.id),
    BigInt.one,
    hexToBytes('0x')
  ];

  print(transactionParameters);

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      parameters: transactionParameters,
      maxGas: gasLimit.toInt(),
      gasPrice: ethGasPrice,
      nonce: nonce);
  String txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment()!.chainId);

    print(txHash);
    return txHash;
  } catch (e) {
    print(e.toString());
    return null;
  }
}

/// Estimates a force Exit Max Gas. This is the L1 transaction equivalent of Exit.
///
/// @param [HermezCompressedAmount] amount - The compressed amount to be withdrawn
/// @param [String] hezEthereumAddress - The Hermez address of the transaction sender
/// @param [String] accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param [Token] token - The token information object as returned from the API
///
/// @returns [BigInt] transaction gas limit
Future<BigInt> forceExitGasLimit(HermezCompressedAmount amount,
    String hezEthereumAddress, String accountIndex, Token token) async {
  BigInt forceExitMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(
      getCurrentEnvironment()!.contracts[ContractName.hermez]!);
  EtherAmount value = EtherAmount.zero();
  Uint8List? data;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment()!.contracts[ContractName.hermez]!,
      ContractName.hermez);

  final transactionParameters = [
    BigInt.zero,
    BigInt.from(getAccountIndex(accountIndex)),
    BigInt.zero,
    BigInt.from(amount.value),
    BigInt.from(token.id),
    BigInt.one,
    hexToBytes('0x')
  ];

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      parameters: transactionParameters);

  data = transaction.data;

  try {
    forceExitMaxGas = await HermezSDK.currentWeb3Client!
        .estimateGas(sender: from, to: to, value: value, data: data);
    forceExitMaxGas += BigInt.from(GAS_LIMIT_DEPOSIT_OFFSET);
    forceExitMaxGas = BigInt.from(
        (forceExitMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));
  } catch (e) {
    forceExitMaxGas = BigInt.from(GAS_LIMIT_LOW);
    forceExitMaxGas = BigInt.from(
        (forceExitMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));
  }

  return forceExitMaxGas;
}

/// Finalise the withdraw. This a L1 transaction.
///
/// @param [BigInt] amount - The amount to be withdrawn
/// @param [String] accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param [Token] token - The token information object as returned from the API
/// @param [String] babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param [int] batchNumber - The batch number of the exit being withdrawn.
/// @param [List<BigInt>] merkleSiblings - An list of BigInts representing the siblings of the exit being withdrawn.
/// @param [String] privateKey - Ethereum private key used to send the transaction
/// @param optional [bool] isInstant - Whether it should be an Instant Withdrawal
/// @param optional [BigInt] gasLimit - Gas limit set for sending the transaction
/// @param optional [int] gasPrice - Gas price set for sending the transaction
///
/// @returns [String] transaction hash
Future<String?> withdraw(
    double amount,
    String? accountIndex,
    Token token,
    String babyJubJub,
    int batchNumber,
    List<BigInt> merkleSiblings,
    String privateKey,
    {bool isInstant = true,
    BigInt? gasLimit,
    int gasPrice = 0}) async {
  final credentials =
      await HermezSDK.currentWeb3Client!.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  if (gasLimit == null) {
    gasLimit = await withdrawGasLimit(amount, from.hex, accountIndex, token,
        babyJubJub, batchNumber, merkleSiblings,
        isInstant: isInstant);
  }

  EtherAmount ethGasPrice;
  if (gasPrice > 0) {
    ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));
  } else {
    ethGasPrice = await HermezSDK.currentWeb3Client!.getGasPrice();
  }

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment()!.contracts[ContractName.hermez]!,
      ContractName.hermez);

  int nonce = await HermezSDK.currentWeb3Client!
      .getTransactionCount(from, atBlock: BlockNum.pending());

  final transactionParameters = [
    BigInt.from(token.id),
    BigInt.from(amount),
    hexToInt(babyJubJub),
    BigInt.from(batchNumber),
    merkleSiblings,
    BigInt.from(getAccountIndex(accountIndex)),
    isInstant,
  ];

  print(transactionParameters);

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _withdrawMerkleProof(hermezContract),
      parameters: transactionParameters,
      maxGas: gasLimit.toInt(),
      gasPrice: ethGasPrice,
      nonce: nonce);

  String? txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment()!.chainId);
    print(txHash);
    return txHash;
  } catch (e) {
    print(e.toString());
    return null;
  }
}

/// Estimates a withdraw Max Gas. This a L1 transaction.
///
/// @param [BigInt] amount - The amount to be withdrawn
/// @param [String] accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param [Token] token - The token information object as returned from the API
/// @param [String] babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param [int] batchNumber - The batch number of the exit being withdrawn.
/// @param [List<BigInt>] merkleSiblings - An list of BigInts representing the siblings of the exit being withdrawn.
/// @param optional [bool] isInstant - Whether it should be an Instant Withdrawal
///
/// @returns [BigInt] transaction gas limit
Future<BigInt> withdrawGasLimit(
    double amount,
    String fromEthereumAddress,
    String? accountIndex,
    Token token,
    String babyJubJub,
    int batchNumber,
    List<BigInt> merkleSiblings,
    {bool isInstant = true}) async {
  /*final hermezContract = await ContractParser.fromAssets('HermezABI.json',
      getCurrentEnvironment()!.contracts['Hermez']!, "Hermez");*/

  BigInt withdrawMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(fromEthereumAddress));
  EthereumAddress to =
      EthereumAddress.fromHex(getCurrentEnvironment()!.contracts['Hermez']!);
  //EtherAmount value = EtherAmount.zero();

  final transactionParameters = [
    BigInt.from(token.id),
    BigInt.from(amount),
    hexToInt(babyJubJub),
    BigInt.from(batchNumber),
    merkleSiblings,
    BigInt.from(getAccountIndex(accountIndex)),
    isInstant,
  ];

  print(transactionParameters);

  /*Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _withdrawMerkleProof(hermezContract),
      parameters: transactionParameters);*/

  //Uint8List? data;
  //data = transaction.data;

  // TODO: FIX ESTIMATE GAS

  /*try {
    withdrawMaxGas = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
  } catch (e) {*/
  // DEFAULT WITHDRAW: 230K + Transfer + (siblings.length * 31K)
  withdrawMaxGas = BigInt.from(GAS_LIMIT_WITHDRAW_DEFAULT);
  if (token.id != 0) {
    withdrawMaxGas += await transferGasLimit(BigInt.from(amount), to.hex,
        from.hex, token.ethereumAddress!, token.name!);
  }
  withdrawMaxGas +=
      BigInt.from(GAS_LIMIT_WITHDRAW_SIBLING * merkleSiblings.length);

  withdrawMaxGas += BigInt.from(GAS_LIMIT_OFFSET);
  //}

  withdrawMaxGas =
      BigInt.from((withdrawMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  return withdrawMaxGas;
}

/// Makes the final withdrawal from the WithdrawalDelayer smart contract after enough time has passed.
///
/// @param [Token] token - The token information object as returned from the API
/// @param [String] privateKey - Ethereum private key used to send the transaction
/// @param optional [BigInt] gasLimit - Gas limit set for sending the transaction
/// @param optional [int] gasPrice - Gas price set for sending the transaction
///
/// @returns [String] transaction hash
Future<String?> delayedWithdraw(Token token, String privateKey,
    {BigInt? gasLimit, int gasPrice = 0}) async {
  final credentials =
      await HermezSDK.currentWeb3Client!.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  if (gasLimit == null) {
    gasLimit = await delayedWithdrawGasLimit(getHermezAddress(from.hex), token);
  }

  EtherAmount ethGasPrice;
  if (gasPrice > 0) {
    ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));
  } else {
    ethGasPrice = await HermezSDK.currentWeb3Client!.getGasPrice();
  }

  int nonce = await HermezSDK.currentWeb3Client!
      .getTransactionCount(from, atBlock: BlockNum.pending());

  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      getCurrentEnvironment()!.contracts[ContractName.withdrawalDelayer]!,
      ContractName.withdrawalDelayer);

  final transactionParameters = [
    from,
    token.id == 0 ? 0x0 : EthereumAddress.fromHex(token.ethereumAddress!)
  ];

  Transaction transaction = Transaction.callContract(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      parameters: transactionParameters,
      maxGas: gasLimit.toInt(),
      gasPrice: ethGasPrice,
      nonce: nonce);

  String? txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client!.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment()!.chainId);
    print(txHash);
    return txHash;
  } catch (e) {
    print(e.toString());
    return null;
  }
}

/// Estimates the delayed withdrawal Max Gas.
///
/// @param [String] hezEthereumAddress - The Hermez address of the transaction sender
/// @param [Token] token - The token information object as returned from the API
///
/// @returns [BigInt] transaction gas limit
Future<BigInt> delayedWithdrawGasLimit(
    String hezEthereumAddress, Token token) async {
  BigInt withdrawMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(
      getCurrentEnvironment()!.contracts[ContractName.withdrawalDelayer]!);
  EtherAmount value = EtherAmount.zero();
  Uint8List? data;

  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      getCurrentEnvironment()!.contracts[ContractName.withdrawalDelayer]!,
      ContractName.withdrawalDelayer);

  final transactionParameters = [
    from,
    token.id == 0 ? 0x0 : EthereumAddress.fromHex(token.ethereumAddress!)
  ];

  Transaction transaction = Transaction.callContract(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      parameters: transactionParameters);

  data = transaction.data;

  try {
    withdrawMaxGas = await HermezSDK.currentWeb3Client!
        .estimateGas(sender: from, to: to, value: value, data: data);
  } catch (e) {
    // DEFAULT DELAYED WITHDRAW: ???? 230K + Transfer + (siblings.length * 31K)
    withdrawMaxGas = BigInt.from(GAS_LIMIT_WITHDRAW_DEFAULT);
    if (token.id != 0) {
      withdrawMaxGas += await transferGasLimit(value.getInWei, to.hex, from.hex,
          token.ethereumAddress!, token.name!);
    }
    //withdrawMaxGas += BigInt.from(GAS_LIMIT_WITHDRAW_SIBLING * merkleSiblings.length);
  }
  withdrawMaxGas += BigInt.from(GAS_LIMIT_OFFSET);
  withdrawMaxGas =
      BigInt.from((withdrawMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  return withdrawMaxGas;
}

/// Checks if the withdraw is allowed to be instant or not.
///
/// @param [double] amount - The amount to be withdrawn
/// @param [Token] token - The token information object as returned from the API
///
/// @returns [BigInt] transaction gas limit
Future<bool> isInstantWithdrawalAllowed(double amount, Token token) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment()!.contracts[ContractName.hermez]!,
      ContractName.hermez);

  final instantWithdrawalCall = await HermezSDK.currentWeb3Client!.call(
      contract: hermezContract,
      function: _instantWithdrawalViewer(hermezContract),
      params: [
        EthereumAddress.fromHex(token.ethereumAddress!),
        BigInt.from(amount),
      ]);
  final allowed = instantWithdrawalCall.first as bool;
  return allowed;
}

/// Sends a L2 transaction to the Coordinator
///
/// @param [Map<String, dynamic>] transaction - Transaction object prepared by TxUtils.generateL2Transaction
/// @param [String] bJJ - The compressed BabyJubJub in hexadecimal format of the transaction sender.
///
/// @return [Map<String, dynamic>] - Object with the response status, transaction id and the transaction nonce
Future<Map<String, dynamic>> sendL2Transaction(
    Map<String, dynamic> transaction, String? bJJ) async {
  Response result = await postPoolTransaction(transaction);

  if (result.statusCode == 200) {
    addPoolTransaction(json.encode(transaction), bJJ);
  }

  return {
    "status": result.statusCode,
    "id": result.body,
    "nonce": transaction['nonce'],
  };
}

/// Compact L2 transaction generated and sent to a Coordinator.
///
/// @param [Map<String, dynamic>] transaction
/// @param [HermezWallet] wallet - Transaction sender Hermez Wallet
/// @param [Token] token - The token information object as returned from the Coordinator.
///
/// @return [Map<String, dynamic>] - Object with the response status, transaction id and the transaction nonce
Future<Map<String, dynamic>> generateAndSendL2Tx(
    Map<String, dynamic> transaction, HermezWallet wallet, Token token) async {
  final Set<Map<String, dynamic>> l2TxParams = await generateL2Transaction(
      transaction, wallet.publicKeyCompressedHex!, token);

  Map<String, dynamic> l2Transaction = l2TxParams.first;
  Map<String, dynamic> l2EncodedTransaction = l2TxParams.last;

  wallet.signTransaction(l2Transaction, l2EncodedTransaction);

  if (l2Transaction["signature"] != null) {
    final l2TxResult =
    await sendL2Transaction(l2Transaction, wallet.publicKeyCompressedHex);

    return l2TxResult;
  } else {
    return {
      "status": 400,
      "id": "error generating signature",
      "nonce": l2Transaction['nonce'],
    };
  }
}
