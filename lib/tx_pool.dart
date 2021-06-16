import 'dart:convert';

import 'package:hermez_sdk/api.dart';
import 'package:hermez_sdk/model/pool_transaction.dart';
import 'package:hermez_sdk/model/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart' show getPoolTransaction;
import 'constants.dart' show TRANSACTION_POOL_KEY;
import 'environment.dart';
import 'model/forged_transaction.dart';

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

/// Fetches the transaction details for each transaction in the pool for the specified account index and bjj
///
/// @param {String} accountIndex - The account index
/// @param {String} bjj - The account's BabyJubJub
///
/// @returns {List<Transaction>}
Future<List<PoolTransaction?>> getPoolTransactions(
    String? accountIndex, String bJJ) async {
  final chainId = getCurrentEnvironment()!.chainId.toString();

  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY) as String);

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
  List<PoolTransaction?> successfulTransactions = [];
  for (String transactionString in accountTransactionPool) {
    final transaction = Transaction.fromJson(json.decode(transactionString));
    ForgedTransaction? historyTransaction;
    // TODO: History tx is needed???
    try {
      historyTransaction = await getHistoryTransaction(transaction.id!);
    } catch (e) {
      print(e.toString());
    }
    try {
      final poolTransaction = await getPoolTransaction(transaction.id!);
      if (historyTransaction != null) {
        // TODO: pool txs are unforged, is it needed??
        if (poolTransaction.info != null || poolTransaction.state == 'fged') {
          removePoolTransaction(bJJ, poolTransaction.id);
        } else {
          successfulTransactions.add(poolTransaction);
        }
      } else {
        successfulTransactions.add(poolTransaction);
      }
    } catch (e) {
      // on ItemNotFoundException {
      if (historyTransaction != null) {
        removePoolTransaction(bJJ, transaction.id);
      }
    }
  }

  return successfulTransactions;
}

/// Adds a transaction to the transaction pool
///
/// @param {string} transaction - The transaction to add to the pool
/// @param {string} bJJ - The account with which the transaction was made
/// @returns {void}
void addPoolTransaction(String transaction, String? bJJ) async {
  final chainId = getCurrentEnvironment()!.chainId.toString();

  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY) as String);

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
///
/// @param [String] bJJ - The account with which the transaction was originally made
/// @param {string} transactionId - The transaction identifier to remove from the pool
/// @returns {void}
void removePoolTransaction(String bJJ, String? transactionId) async {
  final chainId = getCurrentEnvironment()!.chainId.toString();

  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY) as String);

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
