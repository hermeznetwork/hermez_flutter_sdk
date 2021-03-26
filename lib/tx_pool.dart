import 'dart:convert';

import 'package:hermez_plugin/api.dart';
import 'package:hermez_plugin/http_exceptions.dart';
import 'package:hermez_plugin/model/pool_transaction.dart';
import 'package:hermez_plugin/model/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart' show getPoolTransaction;
import 'constants.dart' show TRANSACTION_POOL_KEY;
import 'environment.dart';

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

/// Fetches the transaction details for each transaction in the pool for the specified account index and bjj
///
/// @param {String} accountIndex - The account index
/// @param {String} bjj - The account's BabyJubJub
///
/// @returns {List<Transaction>}
Future<List<PoolTransaction>> getPoolTransactions(
    String accountIndex, String bJJ) async {
  final chainId = getCurrentEnvironment().chainId.toString();

  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final transactionPool = json.decode(prefs.get(TRANSACTION_POOL_KEY));

  final chainIdTransactionPool =
      transactionPool.containsKey(chainId) ? transactionPool[chainId] : {};
  final accountTransactionPool = chainIdTransactionPool.containsKey(bJJ)
      ? chainIdTransactionPool[bJJ]
      : [];

  // filter txs from accountIndex
  accountTransactionPool.removeWhere((transaction) =>
      accountIndex != null &&
      Transaction.fromJson(json.decode(transaction)).fromAccountIndex !=
          accountIndex);
  List<PoolTransaction> successfulTransactions = List();
  for (String transactionString in accountTransactionPool) {
    final transaction = Transaction.fromJson(json.decode(transactionString));
    try {
      final poolTransaction = await getPoolTransaction(transaction.id);
      if (poolTransaction.info != null || poolTransaction.state == 'fged') {
        removePoolTransaction(bJJ, poolTransaction.id);
      } else {
        successfulTransactions.add(poolTransaction);
      }
    } on ItemNotFoundException {
      removePoolTransaction(bJJ, transaction.id);
    }
  }

  return successfulTransactions;
}

/// Adds a transaction to the transaction pool
///
/// @param {string} transaction - The transaction to add to the pool
/// @param {string} bJJ - The account with which the transaction was made
/// @returns {void}
void addPoolTransaction(String transaction, String bJJ) async {
  final chainId = getCurrentEnvironment().chainId.toString();

  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final transactionPool = json.decode(prefs.get(TRANSACTION_POOL_KEY));

  final chainIdTransactionPool =
      transactionPool.containsKey(chainId) ? transactionPool[chainId] : {};
  final accountTransactionPool = chainIdTransactionPool.containsKey(bJJ)
      ? chainIdTransactionPool[bJJ]
      : [];

  final newAccountTransactionPool = List.from(accountTransactionPool);
  newAccountTransactionPool.add(transaction);

  final newChainIdTransactionPool = {}..addAll(chainIdTransactionPool);
  newChainIdTransactionPool.update(bJJ, (value) => newAccountTransactionPool,
      ifAbsent: () => newAccountTransactionPool);

  final newTransactionPool = {}..addAll(transactionPool);
  newTransactionPool.update(chainId, (value) => newChainIdTransactionPool,
      ifAbsent: () => newChainIdTransactionPool);

  prefs.setString(TRANSACTION_POOL_KEY, json.encode(newTransactionPool));
}

/// Removes a transaction from the transaction pool
/// @param {string} bJJ - The account with which the transaction was originally made
/// @param {string} transactionId - The transaction identifier to remove from the pool
/// @returns {void}
void removePoolTransaction(String bJJ, String transactionId) async {
  final chainId = getCurrentEnvironment().chainId.toString();

  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final transactionPool = json.decode(prefs.get(TRANSACTION_POOL_KEY));

  final chainIdTransactionPool =
      transactionPool.containsKey(chainId) ? transactionPool[chainId] : {};
  final accountTransactionPool = chainIdTransactionPool.containsKey(bJJ)
      ? chainIdTransactionPool[bJJ]
      : [];

  accountTransactionPool.removeWhere((transaction) =>
      Transaction.fromJson(json.decode(transaction)).id == transactionId);

  final newChainIdTransactionPool = {}..addAll(chainIdTransactionPool);
  newChainIdTransactionPool.update(bJJ, (value) => accountTransactionPool,
      ifAbsent: () => accountTransactionPool);

  final newTransactionPool = {}..addAll(transactionPool);
  newTransactionPool.update(chainId, (value) => newChainIdTransactionPool,
      ifAbsent: () => newChainIdTransactionPool);

  prefs.setString(TRANSACTION_POOL_KEY, json.encode(newTransactionPool));
}
