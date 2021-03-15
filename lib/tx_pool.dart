import 'dart:convert';

import 'package:hermez_plugin/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart' show getPoolTransaction;
import 'constants.dart' show TRANSACTION_POOL_KEY;

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

/// Fetches the transaction details for each transaction in the pool for the specified account index and bjj
///
/// @param {String} accountIndex - The account index
/// @param {String} bjj - The account's BabyJubJub
///
/// @returns {List<String>}
Future<List<dynamic>> getPoolTransactions(
    String accountIndex, String bJJ) async {
  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final Map<String, dynamic> transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY));
  final accountTransactionsPromises = List<dynamic>();
  if (transactionPool.containsKey(bJJ)) {
    final List<dynamic> accountTransactionPool = transactionPool[bJJ];
    accountTransactionsPromises..addAll(accountTransactionPool);
    accountTransactionsPromises.removeWhere((transaction) =>
        json.decode(transaction)['fromAccountIndex'] == accountIndex);
    accountTransactionsPromises.map((transaction) {
      return getPoolTransaction(json.decode(transaction)['id']);
    });
  }
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
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final Map<String, dynamic> transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY));
  List<String> newAccountTransactionPool;
  if (transactionPool.containsKey(bJJ)) {
    final List<dynamic> accountTransactionPool = transactionPool[bJJ];
    if (accountTransactionPool.isNotEmpty)
      accountTransactionPool.add(transaction);
    newAccountTransactionPool =
        accountTransactionPool.isEmpty ? [transaction] : List<dynamic>()
          ..addAll(accountTransactionPool);
  } else {
    newAccountTransactionPool = [transaction];
  }
  final Map<String, dynamic> newTransactionPool = Map<String, dynamic>()
    ..addAll(transactionPool);
  newTransactionPool.update(bJJ, (value) => newAccountTransactionPool,
      ifAbsent: () => newAccountTransactionPool);
  prefs.setString(TRANSACTION_POOL_KEY, json.encode(newTransactionPool));
}

/// Removes a transaction from the transaction pool
/// @param {string} bJJ - The account with which the transaction was originally made
/// @param {string} transactionId - The transaction identifier to remove from the pool
/// @returns {void}
void removePoolTransaction(String bJJ, String transactionId) async {
  final SharedPreferences prefs = await _prefs;
  if (!prefs.containsKey(TRANSACTION_POOL_KEY)) {
    final emptyTransactionPool = {};
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(emptyTransactionPool));
  }
  final Map<String, dynamic> transactionPool =
      json.decode(prefs.get(TRANSACTION_POOL_KEY));
  if (transactionPool.containsKey(bJJ)) {
    final List<String> accountTransactionPool = transactionPool[bJJ];
    final newAccountTransactionPool = List<String>()
      ..addAll(accountTransactionPool);
    newAccountTransactionPool.removeWhere((String transaction) =>
        json.decode(transaction)['id'] != transactionId);
    final Map<String, dynamic> newTransactionPool = Map<String, dynamic>()
      ..addAll(transactionPool);
    newTransactionPool.update(bJJ, (value) => newAccountTransactionPool,
        ifAbsent: () => newAccountTransactionPool);
    prefs.setString(TRANSACTION_POOL_KEY, json.encode(newTransactionPool));
  }
}
