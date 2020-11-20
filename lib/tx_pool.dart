import 'dart:convert';

import 'package:hermez_plugin/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart' show getPoolTransaction;
import 'constants.dart' show TRANSACTION_POOL_KEY;

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

/// If there's no instance in SharedPreferences for the Transaction Pool, create it
/// This needs to be run when the Hermez client loads
void initializeTransactionPool() async {
  final SharedPreferences prefs = await _prefs;
  if (!prefs.get(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
}

/// Fetches the transaction details for each transaction in the pool for the specified account index and bjj
///
/// @param {String} accountIndex - The account index
/// @param {String} bjj - The account's BabyJubJub
///
/// @returns {List<String>}
Future<List<String>> getPoolTransactions(
    String accountIndex, String bJJ) async {
  final SharedPreferences prefs = await _prefs;
  final Map<String, dynamic> transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY));
  final List<String> accountTransactionPool = transactionPool[bJJ];

  final accountTransactionsPromises = List<String>()
    ..addAll(accountTransactionPool);
  accountTransactionsPromises.removeWhere(
      (transaction) => transaction.fromAccountIndex == accountIndex);
  accountTransactionsPromises.map((transaction) {
    return getPoolTransaction(transaction.id);
  });
  final successfulTransactions = accountTransactionsPromises;
  return successfulTransactions;
}

/// Adds a transaction to the transaction pool
///
/// @param {string} transaction - The transaction to add to the pool
/// @param {string} bJJ - The account with which the transaction was made
/// @returns {void}
void addPoolTransaction(String transaction, String bJJ) async {
  final SharedPreferences prefs = await _prefs;
  final Map<String, dynamic> transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY));
  final List<String> accountTransactionPool = transactionPool[bJJ];
  if (accountTransactionPool.isNotEmpty)
    accountTransactionPool.add(transaction);
  final List<String> newAccountTransactionPool =
      accountTransactionPool.isEmpty ? [transaction] : List<int>()
        ..addAll(accountTransactionPool);
  final Map<String, dynamic> newTransactionPool = Map<String, dynamic>()
    ..addAll(transactionPool);
  newTransactionPool.putIfAbsent(bJJ, () => newAccountTransactionPool);
  prefs.setString(TRANSACTION_POOL_KEY, json.encode(newTransactionPool));
}

/// Removes a transaction from the transaction pool
/// @param {string} bJJ - The account with which the transaction was originally made
/// @param {string} transactionId - The transaction identifier to remove from the pool
/// @returns {void}
void removePoolTransaction(String bJJ, String transactionId) async {
  final SharedPreferences prefs = await _prefs;
  final Map<String, dynamic> transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY));
  final List<dynamic> accountTransactionPool = transactionPool[bJJ];
  final newAccountTransactionPool = List<dynamic>()
    ..addAll(accountTransactionPool);
  newAccountTransactionPool
      .removeWhere((transaction) => transaction.id != transactionId);
  final Map<String, dynamic> newTransactionPool = Map<String, dynamic>()
    ..addAll(transactionPool);
  newTransactionPool.putIfAbsent(bJJ, () => newAccountTransactionPool);
  prefs.setString(TRANSACTION_POOL_KEY, json.encode(newTransactionPool));
}
