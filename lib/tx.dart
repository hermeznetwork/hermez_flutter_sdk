import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hermez_plugin/environment.dart';
import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/model/token.dart';
import 'package:hermez_plugin/tokens.dart';
import 'package:hermez_plugin/utils/contract_parser.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import 'addresses.dart' show getEthereumAddress, getAccountIndex;
import 'api.dart' show getAccounts, postPoolTransaction;
import 'constants.dart'
    show
        BASE_WEB3_RDP_URL,
        BASE_WEB3_URL,
        GAS_LIMIT,
        GAS_LIMIT_ADDL1TX_DEFAULT,
        GAS_LIMIT_DEPOSIT_OFFSET,
        GAS_LIMIT_HIGH,
        GAS_LIMIT_LOW,
        GAS_LIMIT_OFFSET,
        GAS_LIMIT_WITHDRAW_DEFAULT,
        GAS_LIMIT_WITHDRAW_SIBLING,
        GAS_MULTIPLIER,
        GAS_STANDARD_ERC20_TX,
        contractAddresses;
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
    Token token, String babyJubJub, Web3Client web3client, String privateKey,
    {BigInt approveGasLimit,
    BigInt depositGasLimit,
    gasPrice = GAS_MULTIPLIER}) async {
  final ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final accounts = await getAccounts(hezEthereumAddress, [token.id]);

  final Account account = accounts != null && accounts.accounts.isNotEmpty
      ? accounts.accounts[0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  final credentials = await web3client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  EtherAmount ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));

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
    Transaction transaction = Transaction.callContract(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        from: from,
        parameters: transactionParameters,
        maxGas: depositGasLimit.toInt() - 1000,
        gasPrice: ethGasPrice,
        value: EtherAmount.fromUnitAndValue(
            EtherUnit.wei, BigInt.from(decompressedAmount)));

    print(
        'deposit ETH --> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address},'
        ' amountInWei: $decompressedAmount, depositGasLimit: ${depositGasLimit.toInt()}, gasPrice: ${ethGasPrice.getInWei}');

    String txHash;
    try {
      txHash = await web3client.sendTransaction(credentials, transaction,
          chainId: getCurrentEnvironment().chainId);
    } catch (e) {
      print(e.toString());
    }

    print(txHash);

    return txHash;
  }

  int nonceBefore = await web3client.getTransactionCount(from);

  await approve(BigInt.from(decompressedAmount), from.hex,
      token.ethereumAddress, token.name, web3client, credentials,
      gasLimit: approveGasLimit, gasPrice: gasPrice);

  int nonceAfter = await web3client.getTransactionCount(from);

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
      maxGas: depositGasLimit.toInt() - 1000,
      gasPrice: ethGasPrice,
      nonce: correctNonce);

  print(
      'deposit ERC20--> privateKey: $privateKey, sender: $from, receiver: ${hermezContract.address},'
      ' amountInWei: $amount, depositGasLimit: ${depositGasLimit.toInt()}, gasPrice: ${ethGasPrice.getInWei}');

  String txHash;
  try {
    txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {}

  print(txHash);

  return txHash;
}

Future<LinkedHashMap<String, BigInt>> depositGasLimit(
    HermezCompressedAmount amount,
    String hezEthereumAddress,
    Token token,
    String babyJubJub,
    Web3Client web3client) async {
  LinkedHashMap<String, BigInt> result = new LinkedHashMap<String, BigInt>();
  BigInt approveMaxGas = BigInt.zero;
  BigInt depositMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(contractAddresses['Hermez']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final accounts = await getAccounts(hezEthereumAddress, [token.id]);

  final Account account = accounts != null && accounts.accounts.isNotEmpty
      ? accounts.accounts[0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

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
    value = EtherAmount.fromUnitAndValue(
        EtherUnit.wei, BigInt.from(decompressedAmount));
    Transaction transaction = Transaction.callContract(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        from: from,
        parameters: transactionParameters,
        value: value);

    data = transaction.data;

    try {
      depositMaxGas = await web3client.estimateGas(
          sender: from, to: to, value: value, data: data);
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
      ethereumAddress, token.ethereumAddress, token.name, web3client);

  approveMaxGas =
      BigInt.from((approveMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  result['approveGasLimit'] = approveMaxGas;

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      from: from,
      parameters: transactionParameters,
      value: value);

  data = transaction.data;

  try {
    depositMaxGas = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
    depositMaxGas += BigInt.from(GAS_LIMIT_DEPOSIT_OFFSET);
  } catch (e) {
    depositMaxGas = BigInt.from(GAS_LIMIT_HIGH);
    String fromAddress = contractAddresses['Hermez']; // Random ethereum address
    depositMaxGas += await transferGasLimit(
        BigInt.from(decompressedAmount),
        fromAddress,
        ethereumAddress,
        token.ethereumAddress,
        token.name,
        web3client);
  }

  depositMaxGas =
      BigInt.from((depositMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  result['depositGasLimit'] = depositMaxGas;

  print('estimate deposit ERC20 --> Max Gas: $depositMaxGas');

  return result;
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

/// Makes a force Exit. This is the L1 transaction equivalent of Exit.
///
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
Future<String> forceExit(HermezCompressedAmount amount, String accountIndex,
    dynamic token, Web3Client web3client, String privateKey,
    {gasLimit = GAS_LIMIT, gasPrice = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  final credentials = await web3client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  EtherAmount ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));

  int nonce = await web3client.getTransactionCount(from);

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
    txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {}

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
Future<BigInt> forceExitGasLimit(
    String hezEthereumAddress,
    HermezCompressedAmount amount,
    String accountIndex,
    Token token,
    Web3Client web3client) async {
  BigInt forceExitMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(contractAddresses['Hermez']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

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
    forceExitMaxGas = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
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
/// @param {Bumber} gasMultiplier - Optional gas multiplier
Future<String> withdraw(
    BigInt amount,
    String accountIndex,
    Token token,
    String babyJubJub,
    BigInt batchNumber,
    List<BigInt> merkleSiblings,
    Web3Client web3client,
    String privateKey,
    {bool isInstant = true,
    gasLimit = GAS_LIMIT_HIGH,
    gasPrice = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  final credentials = await web3client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  EtherAmount ethGasPrice = EtherAmount.inWei(BigInt.from(gasPrice));

  int nonce = await web3client.getTransactionCount(from);

  final transactionParameters = [
    BigInt.from(token.id),
    amount,
    hexToInt(babyJubJub),
    batchNumber,
    merkleSiblings,
    BigInt.from(getAccountIndex(accountIndex)),
    isInstant,
  ];

  print(transactionParameters);

  Transaction transaction = Transaction.callContract(
      contract: hermezContract,
      function: _withdrawMerkleProof(hermezContract),
      parameters: transactionParameters,
      maxGas: gasLimit,
      gasPrice: ethGasPrice,
      nonce: nonce);

  String txHash;
  try {
    txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {
    print(e.toString());
  }

  print(txHash);

  return txHash;
}

Future<BigInt> withdrawGasLimit(
    BigInt amount,
    String hezEthereumAddress,
    String accountIndex,
    Token token,
    String babyJubJub,
    BigInt batchNumber,
    List<BigInt> merkleSiblings,
    Web3Client web3client,
    {bool isInstant = true}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  BigInt withdrawMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to = EthereumAddress.fromHex(contractAddresses['Hermez']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final transactionParameters = [
    BigInt.from(token.id),
    amount,
    hexToInt(babyJubJub),
    batchNumber,
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

  try {
    withdrawMaxGas = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
  } catch (e) {
    // DEFAULT WITHDRAW: 230K + Transfer + (siblings.length * 31K)
    withdrawMaxGas = BigInt.from(GAS_LIMIT_WITHDRAW_DEFAULT);
    if (token.id != 0) {
      withdrawMaxGas += await transferGasLimit(amount, to.hex, from.hex,
          token.ethereumAddress, token.name, web3client);
    }
    withdrawMaxGas +=
        BigInt.from(GAS_LIMIT_WITHDRAW_SIBLING * merkleSiblings.length);
  }

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
Future<String> delayedWithdraw(
    Token token, Web3Client web3client, String privateKey,
    {gasLimit = GAS_LIMIT, gasPrice = GAS_MULTIPLIER}) async {
  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      contractAddresses['WithdrawalDelayer'],
      "WithdrawalDelayer");

  final credentials = await web3client.credentialsFromPrivateKey(privateKey);
  final from = await credentials.extractAddress();

  final transactionParameters = [
    from,
    token.id == 0 ? 0x0 : token.ethereumAddress
  ];

  Transaction transaction = Transaction.callContract(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      parameters: transactionParameters,
      maxGas: gasLimit,
      gasPrice: gasPrice);

  String txHash;
  try {
    txHash = await web3client.sendTransaction(credentials, transaction,
        chainId: getCurrentEnvironment().chainId);
  } catch (e) {}

  print(txHash);

  return txHash;
}

Future<BigInt> delayedWithdrawGasLimit(
    String hezEthereumAddress, Token token, Web3Client web3client) async {
  BigInt withdrawMaxGas = BigInt.zero;
  EthereumAddress from =
      EthereumAddress.fromHex(getEthereumAddress(hezEthereumAddress));
  EthereumAddress to =
      EthereumAddress.fromHex(contractAddresses['WithdrawalDelayer']);
  EtherAmount value = EtherAmount.zero();
  Uint8List data;

  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      contractAddresses['WithdrawalDelayer'],
      "WithdrawalDelayer");

  final transactionParameters = [
    from,
    token.id == 0 ? 0x0 : token.ethereumAddress
  ];

  Transaction transaction = Transaction.callContract(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      parameters: transactionParameters);

  data = transaction.data;

  try {
    withdrawMaxGas = await web3client.estimateGas(
        sender: from, to: to, value: value, data: data);
  } catch (e) {
    // DEFAULT DELAYED WITHDRAW: ???? 230K + Transfer + (siblings.length * 31K)
    withdrawMaxGas = BigInt.from(GAS_LIMIT_WITHDRAW_DEFAULT);
    if (token.id != 0) {
      withdrawMaxGas += await transferGasLimit(value.getInWei, to.hex, from.hex,
          token.ethereumAddress, token.name, web3client);
    }
    //withdrawMaxGas += BigInt.from(GAS_LIMIT_WITHDRAW_SIBLING * merkleSiblings.length);
  }

  withdrawMaxGas =
      BigInt.from((withdrawMaxGas.toInt() / pow(10, 3)).floor() * pow(10, 3));

  return withdrawMaxGas;
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
