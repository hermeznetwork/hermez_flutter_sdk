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

import 'addresses.dart' show getEthereumAddress, getAccountIndex;
import 'api.dart' show getAccounts, postPoolTransaction;
import 'constants.dart'
    show
        GAS_LIMIT,
        GAS_LIMIT_DEPOSIT_OFFSET,
        GAS_LIMIT_HIGH,
        GAS_LIMIT_LOW,
        GAS_LIMIT_OFFSET,
        GAS_LIMIT_WITHDRAW_DEFAULT,
        GAS_LIMIT_WITHDRAW_SIBLING,
        GAS_MULTIPLIER,
        GAS_STANDARD_ERC20_TX;
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

ContractEvent _addTokenEvent(DeployedContract contract) =>
    contract.event('AddToken');
ContractEvent _l1UserTxEvent(DeployedContract contract) =>
    contract.event('L1UserTxEvent');

/// Get current average gas price from the last ethereum blocks and multiply it
/// @param {Number} multiplier - multiply the average gas price by this parameter
/// @param {Web3Client} web3Client - Network url (i.e, http://localhost:8545). Optional
/// @returns {Future<int>} - will return the gas price obtained.
Future<int> getGasPrice(num multiplier, Web3Client web3client) async {
  EtherAmount strAvgGas = await web3client.getGasPrice();
  BigInt avgGas = strAvgGas.getInWei;
  BigInt res = avgGas * BigInt.from(multiplier);
  int retValue = res.toInt();
  return retValue;
}

/// Makes a deposit.
/// It detects if it's a 'createAccountDeposit' or a 'deposit' and prepares the parameters accordingly.
/// Detects if it's an Ether, ERC 20 token and sends the transaction accordingly.
///
/// @param {BigInt} amount - The amount to be deposited
/// @param {String} hezEthereumAddress - The Hermez address of the transaction sender
/// @param {Object} token - The token information object as returned from the API
/// @param {String} babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
///
/// @returns {String} transaction hash
Future<String> deposit(HermezCompressedAmount amount, String hezEthereumAddress,
    Token token, String babyJubJub, String privateKey,
    {BigInt approveMaxGas, BigInt depositMaxGas, int gasPrice = 0}) async {
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
    ethGasPrice = await HermezSDK.currentWeb3Client.getGasPrice();
  }

  final accounts = await getAccounts(hezEthereumAddress, [token.id]);
  final Account account = accounts != null && accounts.accounts.isNotEmpty
      ? accounts.accounts[0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', getCurrentEnvironment().contracts['Hermez'], "Hermez");

  final credentials =
      await HermezSDK.currentWeb3Client.credentialsFromPrivateKey(privateKey);
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
    int nonce = await HermezSDK.currentWeb3Client
        .getTransactionCount(from, atBlock: BlockNum.pending());

    Transaction transaction = Transaction.callContract(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        from: from,
        parameters: transactionParameters,
        maxGas: depositMaxGas.toInt() - 1000,
        gasPrice: ethGasPrice,
        value: EtherAmount.fromUnitAndValue(
            EtherUnit.wei, BigInt.from(decompressedAmount)),
        nonce: nonce);

    print(
        'deposit ETH --> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address},'
        ' amountInWei: $decompressedAmount, depositGasLimit: ${depositMaxGas.toInt()}, gasPrice: ${ethGasPrice.getInWei}');

    String txHash;
    try {
      txHash = await HermezSDK.currentWeb3Client.sendTransaction(
          credentials, transaction,
          chainId: getCurrentEnvironment().chainId);
    } catch (e) {
      print(e.toString());
    }

    print(txHash);

    return txHash;
  }

  int nonceBefore = await HermezSDK.currentWeb3Client
      .getTransactionCount(from, atBlock: BlockNum.pending());

  await approve(BigInt.from(decompressedAmount), from.hex,
      token.ethereumAddress, token.name, credentials,
      gasLimit: approveMaxGas, gasPrice: gasPrice);

  int nonceAfter = await HermezSDK.currentWeb3Client
      .getTransactionCount(from, atBlock: BlockNum.pending());

  int correctNonce = nonceAfter;

  if (nonceBefore == nonceAfter) {
    correctNonce = nonceAfter + 1;
  }

  // Keep in mind that web3.eth.getTransactionCount(walletAddress)
  // will only give you the last CONFIRMED nonce.
  // So it won't take the unmined ones into account.

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      parameters: transactionParameters,
      maxGas: depositMaxGas.toInt() - 1000,
      gasPrice: ethGasPrice,
      nonce: correctNonce);

  print(
      'deposit ERC20--> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address},'
      ' amountInWei: $amount, depositGasLimit: ${depositMaxGas.toInt()}, gasPrice: ${ethGasPrice.getInWei}');

  String txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {
    print(e.toString());
  }

  print(txHash);

  return txHash;
}

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
      getCurrentEnvironment().contracts[ContractName.hermez]);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final accounts = await getAccounts(hezEthereumAddress, [token.id]);

  final Account account = accounts != null && accounts.accounts.isNotEmpty
      ? accounts.accounts[0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment().contracts[ContractName.hermez],
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
      depositMaxGas = await HermezSDK.currentWeb3Client
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
      ethereumAddress, token.ethereumAddress, token.name);

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
    depositMaxGas = await HermezSDK.currentWeb3Client
        .estimateGas(sender: from, to: to, value: value, data: data);
    depositMaxGas += BigInt.from(GAS_LIMIT_DEPOSIT_OFFSET);
  } catch (e) {
    depositMaxGas = BigInt.from(GAS_LIMIT_HIGH);
    String fromAddress = getCurrentEnvironment()
        .contracts[ContractName.hermez]; // Random ethereum address
    depositMaxGas += await transferGasLimit(BigInt.from(decompressedAmount),
        fromAddress, ethereumAddress, token.ethereumAddress, token.name);
  }

  depositMaxGas =
      BigInt.from((depositMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  result['depositGasLimit'] = depositMaxGas;

  print('estimate deposit ERC20 --> Max Gas: $depositMaxGas');

  return result;
}

/// Makes a force Exit. This is the L1 transaction equivalent of Exit.
///
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {Object} privateKey - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
Future<String> forceExit(HermezCompressedAmount amount, String accountIndex,
    Token token, String privateKey,
    {gasLimit = GAS_LIMIT, gasPrice = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', getCurrentEnvironment().contracts['Hermez'], "Hermez");

  final credentials =
      await HermezSDK.currentWeb3Client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  EtherAmount ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));

  int nonce = await HermezSDK.currentWeb3Client
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
      maxGas: gasLimit,
      gasPrice: ethGasPrice,
      nonce: nonce);
  String txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {
    print(e.toString());
  }

  print(txHash);

  return txHash;
}

/// Estimates a force Exit Max Gas. This is the L1 transaction equivalent of Exit.
///
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
Future<BigInt> forceExitGasLimit(String hezEthereumAddress,
    HermezCompressedAmount amount, String accountIndex, Token token) async {
  BigInt forceExitMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to =
      EthereumAddress.fromHex(getCurrentEnvironment().contracts['Hermez']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', getCurrentEnvironment().contracts['Hermez'], "Hermez");

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
    forceExitMaxGas = await HermezSDK.currentWeb3Client
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
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {String} babyJubJub - The compressed BabyJubJub in hexadecimal format of the transaction sender.
/// @param {BigInt} merkleRoot - The merkle root of the exit being withdrawn.
/// @param {Array} merkleSiblings - An array of BigInts representing the siblings of the exit being withdrawn.
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Boolean} isInstant - Whether it should be an Instant Withdrawal
/// @param {Boolean} filterSiblings - Whether siblings should be filtered
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasPrice - Optional gas price
Future<String> withdraw(
    double amount,
    String accountIndex,
    Token token,
    String babyJubJub,
    int batchNumber,
    List<BigInt> merkleSiblings,
    String privateKey,
    {bool isInstant = true,
    BigInt gasLimit,
    int gasPrice = 0}) async {
  final credentials =
      await HermezSDK.currentWeb3Client.credentialsFromPrivateKey(privateKey);
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
    ethGasPrice = await HermezSDK.currentWeb3Client.getGasPrice();
  }

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment().contracts[ContractName.hermez],
      ContractName.hermez);

  int nonce = await HermezSDK.currentWeb3Client
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

  String txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {
    print(e.toString());
  }

  print(txHash);

  return txHash;
}

Future<BigInt> withdrawGasLimit(
    double amount,
    String fromEthereumAddress,
    String accountIndex,
    Token token,
    String babyJubJub,
    int batchNumber,
    List<BigInt> merkleSiblings,
    {bool isInstant = true}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', getCurrentEnvironment().contracts['Hermez'], "Hermez");

  BigInt withdrawMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(fromEthereumAddress));
  EthereumAddress to =
      EthereumAddress.fromHex(getCurrentEnvironment().contracts['Hermez']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

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
      parameters: transactionParameters);

  data = transaction.data;

  // TODO: FIX ESTIMATE GAS

  /*try {
    withdrawMaxGas = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
  } catch (e) {*/
  // DEFAULT WITHDRAW: 230K + Transfer + (siblings.length * 31K)
  withdrawMaxGas = BigInt.from(GAS_LIMIT_WITHDRAW_DEFAULT);
  if (token.id != 0) {
    withdrawMaxGas += await transferGasLimit(BigInt.from(amount), to.hex,
        from.hex, token.ethereumAddress, token.name);
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
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasPrice - Optional gas price
Future<String> delayedWithdraw(Token token, String privateKey,
    {BigInt gasLimit, int gasPrice = 0}) async {
  final credentials =
      await HermezSDK.currentWeb3Client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  if (gasLimit == null) {
    gasLimit = await delayedWithdrawGasLimit(from.hex, token);
  }

  EtherAmount ethGasPrice;
  if (gasPrice > 0) {
    ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));
  } else {
    ethGasPrice = await HermezSDK.currentWeb3Client.getGasPrice();
  }

  int nonce = await HermezSDK.currentWeb3Client
      .getTransactionCount(from, atBlock: BlockNum.pending());

  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      getCurrentEnvironment().contracts[ContractName.withdrawalDelayer],
      ContractName.withdrawalDelayer);

  final transactionParameters = [
    from,
    token.id == 0 ? 0x0 : EthereumAddress.fromHex(token.ethereumAddress)
  ];

  Transaction transaction = Transaction.callContract(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      parameters: transactionParameters,
      maxGas: gasLimit.toInt(),
      gasPrice: ethGasPrice,
      nonce: nonce);

  String txHash;
  try {
    txHash = await HermezSDK.currentWeb3Client.sendTransaction(
        credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {
    print(e.toString());
  }

  print(txHash);

  return txHash;
}

Future<BigInt> delayedWithdrawGasLimit(
    String fromEthereumAddress, Token token) async {
  BigInt withdrawMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(fromEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(
      getCurrentEnvironment().contracts[ContractName.withdrawalDelayer]);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      getCurrentEnvironment().contracts[ContractName.withdrawalDelayer],
      ContractName.withdrawalDelayer);

  final transactionParameters = [
    from,
    token.id == 0 ? 0x0 : EthereumAddress.fromHex(token.ethereumAddress)
  ];

  Transaction transaction = Transaction.callContract(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      parameters: transactionParameters);

  data = transaction.data;

  try {
    withdrawMaxGas = await HermezSDK.currentWeb3Client
        .estimateGas(sender: from, to: to, value: value, data: data);
  } catch (e) {
    // DEFAULT DELAYED WITHDRAW: ???? 230K + Transfer + (siblings.length * 31K)
    withdrawMaxGas = BigInt.from(GAS_LIMIT_WITHDRAW_DEFAULT);
    if (token.id != 0) {
      withdrawMaxGas += await transferGasLimit(
          value.getInWei, to.hex, from.hex, token.ethereumAddress, token.name);
    }
    //withdrawMaxGas += BigInt.from(GAS_LIMIT_WITHDRAW_SIBLING * merkleSiblings.length);
  }
  withdrawMaxGas += BigInt.from(GAS_LIMIT_OFFSET);
  withdrawMaxGas =
      BigInt.from((withdrawMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  return withdrawMaxGas;
}

Future<bool> isInstantWithdrawalAllowed(double amount, Token token) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json',
      getCurrentEnvironment().contracts[ContractName.hermez],
      ContractName.hermez);

  final instantWithdrawalCall = await HermezSDK.currentWeb3Client.call(
      contract: hermezContract,
      function: _instantWithdrawalViewer(hermezContract),
      params: [
        EthereumAddress.fromHex(token.ethereumAddress),
        BigInt.from(amount),
      ]);
  final allowed = instantWithdrawalCall.first as bool;
  return allowed;
}

/// Sends a L2 transaction to the Coordinator
///
/// @param {Object} transaction - Transaction object prepared by TxUtils.generateL2Transaction
/// @param {String} bJJ - The compressed BabyJubJub in hexadecimal format of the transaction sender.
///
/// @return {Object} - Object with the response status, transaction id and the transaction nonce
dynamic sendL2Transaction(Map<String, dynamic> transaction, String bJJ) async {
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
/// @param {Object} transaction - ethAddress and babyPubKey together
/// @param {String} transaction.from - The account index that's sending the transaction e.g hez:DAI:4444
/// @param {String} transaction.to - The account index of the receiver e.g hez:DAI:2156. If it's an Exit, set to a falseable value
/// @param {BigInt} transaction.amount - The amount being sent as a BigInt
/// @param {Number} transaction.fee - The amount of tokens to be sent as a fee to the Coordinator
/// @param {Number} transaction.nonce - The current nonce of the sender's token account
/// @param {HermezWallet} wallet - Transaction sender Hermez Wallet
/// @param {Token} token - The token information object as returned from the Coordinator.
dynamic generateAndSendL2Tx(
    dynamic transaction, HermezWallet wallet, Token token) async {
  final Set<Map<String, dynamic>> l2TxParams = await generateL2Transaction(
      transaction, wallet.publicKeyCompressedHex, token);

  Map<String, dynamic> l2Transaction = l2TxParams.first;
  Map<String, dynamic> l2EncodedTransaction = l2TxParams.last;

  wallet.signTransaction(l2Transaction, l2EncodedTransaction);

  final l2TxResult =
      await sendL2Transaction(l2Transaction, wallet.publicKeyCompressedHex);

  return l2TxResult;
}
