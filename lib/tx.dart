import 'dart:convert' show json;
import 'dart:typed_data';

import 'package:hermez_plugin/hermez_wallet.dart';
import 'package:hermez_plugin/utils/contract_parser.dart';
import 'package:web3dart/web3dart.dart';

import 'addresses.dart' show getEthereumAddress, getAccountIndex;
import 'api.dart' show getAccounts, postPoolTransaction;
import 'constants.dart' show GAS_LIMIT, GAS_MULTIPLIER, contractAddresses;
import 'model/account.dart';
import 'model/accounts_response.dart';
import 'tokens.dart' show approve;
import 'tx_pool.dart' show addPoolTransaction;
import 'tx_utils.dart' show generateL2Transaction;

ContractFunction _addL1Transaction(DeployedContract contract) =>
    contract.function('addL1Transaction');
ContractFunction _withdrawMerkleProof(DeployedContract contract) =>
    contract.function('withdrawMerkleProof');
ContractFunction _withdrawal(DeployedContract contract) =>
    contract.function('withdrawal');

/// Get current average gas price from the last ethereum blocks and multiply it
/// @param {Number} multiplier - multiply the average gas price by this parameter
/// @param {Web3Client} web3Client - Network url (i.e, http://localhost:8545). Optional
/// @returns {Future<int>} - will return the gas price obtained.
Future<int> getGasPrice(num multiplier, Web3Client web3client) async {
  EtherAmount strAvgGas = await web3client.getGasPrice();
  BigInt avgGas = strAvgGas.getInEther;
  BigInt res = avgGas * BigInt.from(multiplier);
  int retValue = res.toInt(); //toString();
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
/// @returns {Promise} transaction
Future<bool> deposit(BigInt amount, String hezEthereumAddress, dynamic token,
    String babyJubJub, Web3Client web3client,
    {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
  final ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final accountsResponse = await getAccounts(hezEthereumAddress, [token.id]);

  final AccountsResponse accounts =
      AccountsResponse.fromJson(json.decode(accountsResponse));
  final Account account = accounts != null && accounts.accounts.isNotEmpty
      ? accounts.accounts[0]
      : null;

  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final transactionParameters = [
    account != null ? BigInt.zero : BigInt.parse('0x' + babyJubJub, radix: 16),
    account != null
        ? BigInt.from(getAccountIndex(account.accountIndex))
        : BigInt.zero,
    BigInt.from(1),
    BigInt.zero,
    BigInt.from(token.id),
    BigInt.zero
  ];

  print([...transactionParameters, overrides]);

  if (token.id == 0) {
    overrides = Uint8List.fromList([amount.toInt()]);
    print([...transactionParameters, overrides]);
    final addL1TransactionCall = await web3client.call(
        contract: hermezContract,
        function: _addL1Transaction(hermezContract),
        params: [...transactionParameters, overrides]);

    return true;
  }

  await approve(
      amount, ethereumAddress, token.ethereumAddress, token.name, web3client);

  final addL1TransactionCall = await web3client.call(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      params: [...transactionParameters, overrides]);

  return true;
}

/// Makes a force Exit. This is the L1 transaction equivalent of Exit.
///
/// @param {BigInt} amount - The amount to be withdrawn
/// @param {String} accountIndex - The account index in hez address format e.g. hez:DAI:4444
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Number} gasMultiplier - Optional gas multiplier
void forceExit(
    BigInt amount, String accountIndex, dynamic token, Web3Client web3client,
    {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final transactionParameters = [
    BigInt.zero,
    getAccountIndex(accountIndex),
    BigInt.zero,
    amount,
    token.id,
    1,
    '0x'
  ];

  final addL1TransactionCall = await web3client.call(
      contract: hermezContract,
      function: _addL1Transaction(hermezContract),
      params: [...transactionParameters, overrides]);
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
void withdraw(
    BigInt amount,
    String accountIndex,
    dynamic token,
    String babyJubJub,
    BigInt batchNumber,
    List<BigInt> merkleSiblings,
    Web3Client web3client,
    {bool isInstant = true,
    gasLimit = GAS_LIMIT,
    gasMultiplier = GAS_MULTIPLIER}) async {
  final hermezContract = await ContractParser.fromAssets(
      'HermezABI.json', contractAddresses['Hermez'], "Hermez");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final transactionParameters = [
    token.id,
    amount,
    '0x$babyJubJub',
    batchNumber,
    merkleSiblings,
    getAccountIndex(accountIndex),
    isInstant,
  ];

  print([...transactionParameters, overrides]);

  final l1Transaction = new List()..addAll(transactionParameters);
  l1Transaction.add(overrides);

  final withdrawMerkleProofCall = await web3client.call(
      contract: hermezContract,
      function: _withdrawMerkleProof(hermezContract),
      params: [...transactionParameters, overrides]);
}

/// Makes the final withdrawal from the WithdrawalDelayer smart contract after enough time has passed.
///
/// @param {String} hezEthereumAddress - The Hermez address of the transaction sender
/// @param {Object} token - The token information object as returned from the API
/// @param {String} providerUrl - Network url (i.e, http://localhost:8545). Optional
/// @param {Object} signerData - Signer data used to build a Signer to send the transaction
/// @param {Number} gasLimit - Optional gas limit
/// @param {Bumber} gasMultiplier - Optional gas multiplier
void delayedWithdraw(
    String hezEthereumAddress, dynamic token, Web3Client web3client,
    {gasLimit = GAS_LIMIT, gasMultiplier = GAS_MULTIPLIER}) async {
  final withdrawalDelayerContract = await ContractParser.fromAssets(
      'WithdrawalDelayerABI.json',
      contractAddresses['WithdrawalDelayer'],
      "WithdrawalDelayer");

  dynamic overrides = Uint8List.fromList(
      [gasLimit, await getGasPrice(gasMultiplier, web3client)]);

  final String ethereumAddress = getEthereumAddress(hezEthereumAddress);

  final transactionParameters = [
    ethereumAddress,
    token.id == 0 ? 0x0 : token.ethereumAddress
  ];

  final delayedWithdrawalCall = await web3client.call(
      contract: withdrawalDelayerContract,
      function: _withdrawal(withdrawalDelayerContract),
      params: [...transactionParameters, overrides]);
}

/// Sends a L2 transaction to the Coordinator
///
/// @param {Object} transaction - Transaction object prepared by TxUtils.generateL2Transaction
/// @param {String} bJJ - The compressed BabyJubJub in hexadecimal format of the transaction sender.
///
/// @return {Object} - Object with the response status, transaction id and the transaction nonce
dynamic sendL2Transaction(dynamic transaction, String bJJ) async {
  dynamic result = await postPoolTransaction(transaction);

  if (result.status == 200) {
    addPoolTransaction(transaction, bJJ);
  }

  return {
    "status": result.status,
    "id": result.data,
    "nonce": transaction.nonce,
  };
}

/// Compact L2 transaction generated and sent to a Coordinator.
/// @param {Object} transaction - ethAddress and babyPubKey together
/// @param {String} transaction.from - The account index that's sending the transaction e.g hez:DAI:4444
/// @param {String} transaction.to - The account index of the receiver e.g hez:DAI:2156. If it's an Exit, set to a falseable value
/// @param {BigInt} transaction.amount - The amount being sent as a BigInt
/// @param {Number} transaction.fee - The amount of tokens to be sent as a fee to the Coordinator
/// @param {Number} transaction.nonce - The current nonce of the sender's token account
/// @param {Object} wallet - Transaction sender Hermez Wallet
/// @param {Object} token - The token information object as returned from the Coordinator.
dynamic generateAndSendL2Tx(
    dynamic transaction, HermezWallet wallet, dynamic token) async {
  final l2TxParams = await generateL2Transaction(
      transaction, wallet.publicKeyCompressedHex, token);

  wallet.signTransaction(l2TxParams.transaction, l2TxParams.encodedTransaction);

  final l2TxResult = await sendL2Transaction(
      l2TxParams.transaction, wallet.publicKeyCompressedHex);

  return l2TxResult;
}
