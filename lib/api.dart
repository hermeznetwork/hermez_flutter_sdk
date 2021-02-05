import 'dart:convert';

import 'package:hermez_plugin/http.dart' show extractJSON, get, post;
import 'package:hermez_plugin/model/tokens_response.dart';
import 'package:http/http.dart' as http;

import 'addresses.dart' show isHermezEthereumAddress, isHermezBjjAddress;
import 'constants.dart' show BASE_API_URL, DEFAULT_PAGE_SIZE;
import 'model/accounts_response.dart';
import 'model/exits_response.dart';
import 'model/state_response.dart';

var baseApiUrl = BASE_API_URL;

const REGISTER_AUTH_URL = "/account-creation-authorization";
const ACCOUNTS_URL = "/accounts";
const EXITS_URL = "/exits";
const STATE_URL = "/state";

const TRANSACTIONS_POOL_URL = "/transactions-pool";
const TRANSACTIONS_HISTORY_URL = "/transactions-history";

const TOKENS_URL = "/tokens";
const RECOMMENDED_FEES_URL = "/recommendedFee";
const COORDINATORS_URL = "/coordinators";

const BATCHES_URL = "/batches";
const SLOTS_URL = "/slots";
const BIDS_URL = "/bids";
const ACCOUNT_CREATION_AUTH_URL = "/account-creation-authorization";

enum PaginationOrder { ASC, DESC }

/// Sets the query parameters related to pagination
/// @param {int} fromItem - Item from where to start the request
/// @returns {object} Includes the values `fromItem` and `limit`
/// @private
Map<String, String> getPageData(
    int fromItem, PaginationOrder order, int limit) {
  Map<String, String> params = {};
  params.putIfAbsent('fromItem',
      () => fromItem != null && fromItem >= 0 ? fromItem.toString() : {});
  params.putIfAbsent('order', () => order.toString().split(".")[1]);
  params.putIfAbsent('limit', () => DEFAULT_PAGE_SIZE.toString());
  return params;
}

/// Sets the current coordinator API URL
/// @param {String} url - The currently forging Coordinator
void setBaseApiUrl(String url) {
  baseApiUrl = url;
}

/// Returns current coordinator API URL
/// @returns {String} The currently set Coordinator
String getBaseApiUrl() {
  return baseApiUrl;
}

/// GET request to the /accounts endpoint. Returns a list of token accounts associated to a Hermez address
/// @param {string} address - The account's address. It can be a Hermez Ethereum address or a Hermez BabyJubJub address
/// @param {int[]} tokenIds - Array of token IDs as registered in the network
/// @param {int} fromItem - Item from where to start the request
/// @returns {object} Response data with filtered token accounts and pagination data
Future<AccountsResponse> getAccounts(String address, List<int> tokenIds,
    {int fromItem = 0,
    PaginationOrder order = PaginationOrder.ASC,
    int limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String> params = {};
  if (isHermezEthereumAddress(address) && address.isNotEmpty)
    params.putIfAbsent('hezEthereumAddress', () => address);
  else if (isHermezBjjAddress(address) && address.isNotEmpty)
    params.putIfAbsent('BJJ', () => address);
  if (tokenIds.isNotEmpty)
    params.putIfAbsent('tokenIds', () => tokenIds.join(','));
  params.putIfAbsent('order', () => order.toString());
  params.addAll(getPageData(fromItem, order, limit));
  final response = await get(baseApiUrl, ACCOUNTS_URL, queryParameters: params);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final AccountsResponse accountsResponse =
        AccountsResponse.fromJson(json.decode(jsonResponse));
    return accountsResponse;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /accounts/:accountIndex endpoint. Returns a specific token account for an accountIndex
/// @param {string} accountIndex - Account index in the format hez:DAI:4444
/// @returns {object} Response data with the token account
Future<String> getAccount(String accountIndex) async {
  return extractJSON(await get(baseApiUrl, ACCOUNTS_URL + '/' + accountIndex));
}

/// GET request to the /transactions-histroy endpoint. Returns a list of forged transaction based on certain filters
/// @param {string} address - Filter by the address that sent or received the transactions. It can be a Hermez Ethereum address or a Hermez BabyJubJub address
/// @param {int[]} tokenIds - Array of token IDs as registered in the network
/// @param {int} batchNum - Filter by batch number
/// @param {String} accountIndex - Filter by an account index that sent or received the transactions
/// @param {int} fromItem - Item from where to start the request
/// @returns {object} Response data with filtered transactions and pagination data
Future<String> getTransactions(
    String address, List<int> tokenIds, int batchNum, String accountIndex,
    {int fromItem = 0,
    PaginationOrder order = PaginationOrder.ASC,
    int limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String> params = {};
  if (isHermezEthereumAddress(address) && address.isNotEmpty)
    params.putIfAbsent('hezEthereumAddress', () => address);
  if (isHermezBjjAddress(address) && address.isNotEmpty)
    params.putIfAbsent('BJJ', () => address);
  if (tokenIds.isNotEmpty)
    params.putIfAbsent('tokenIds', () => tokenIds.join(','));
  params.putIfAbsent('batchNum', () => batchNum > 0 ? batchNum.toString() : '');
  params.putIfAbsent('accountIndex', () => accountIndex);
  params.addAll(getPageData(fromItem, order, limit));
  return extractJSON(
      await get(baseApiUrl, TRANSACTIONS_HISTORY_URL, queryParameters: params));
}

/// GET request to the /transactions-history/:transactionId endpoint. Returns a specific forged transaction
/// @param {string} transactionId - The ID for the specific transaction
/// @returns {object} Response data with the transaction
Future<String> getHistoryTransaction(String transactionId) async {
  return extractJSON(
      await get(baseApiUrl, TRANSACTIONS_HISTORY_URL + '/' + transactionId));
}

/// GET request to the /transactions-pool/:transactionId endpoint. Returns a specific unforged transaction
/// @param {string} transactionId - The ID for the specific transaction
/// @returns {object} Response data with the transaction
Future<String> getPoolTransaction(String transactionId) async {
  return extractJSON(
      await get(baseApiUrl, TRANSACTIONS_POOL_URL + '/' + transactionId));
}

/// POST request to the /transaction-pool endpoint. Sends an L2 transaction to the network
/// @param {object} transaction - Transaction data returned by TxUtils.generateL2Transaction
/// @returns {string} Transaction id
Future<String> postPoolTransaction(dynamic transaction) async {
  return extractJSON(
      await post(baseApiUrl, TRANSACTIONS_POOL_URL, body: transaction));
}

/// GET request to the /exits endpoint. Returns a list of exits based on certain filters
/// @param {string} address - Filter by the address associated to the exits. It can be a Hermez Ethereum address or a Hermez BabyJubJub address
/// @param {boolean} onlyPendingWithdraws - Filter by exits that still haven't been withdrawn
/// @returns {object} Response data with the list of exits
Future<ExitsResponse> getExits(
    String address, bool onlyPendingWithdraws) async {
  Map<String, String> params = {};
  if (isHermezEthereumAddress(address) && address.isNotEmpty)
    params.putIfAbsent('hezEthereumAddress', () => address);
  if (isHermezBjjAddress(address) && address.isNotEmpty)
    params.putIfAbsent('BJJ', () => address);
  params.putIfAbsent(
      'onlyPendingWithdraws', () => onlyPendingWithdraws.toString());
  final response = await extractJSON(
      await get(baseApiUrl, EXITS_URL, queryParameters: params));
  final ExitsResponse exitsResponse =
      ExitsResponse.fromJson(json.decode(response));
  return exitsResponse;
}

/// GET request to the /exits/:batchNum/:accountIndex endpoint. Returns a specific exit
/// @param {int} batchNum - Filter by an exit in a specific batch number
/// @param {string} accountIndex - Filter by an exit associated to an account index
/// @returns {object} Response data with the specific exit
Future<String> getExit(int batchNum, String accountIndex) async {
  return extractJSON(await get(
      baseApiUrl, EXITS_URL + '/' + batchNum.toString() + '/' + accountIndex));
}

/// GET request to the /tokens endpoint. Returns a list of token data
/// @param {int[]} tokenIds - An array of token IDs
/// @returns {object} Response data with the list of tokens
Future<TokensResponse> getTokens(
    {List<int> tokenIds,
    int fromItem = 0,
    order = PaginationOrder.ASC,
    limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String> params = {};
  if (tokenIds != null && tokenIds.isNotEmpty)
    params.putIfAbsent(
        'ids', () => tokenIds.isNotEmpty ? tokenIds.join(',') : '');
  params.addAll(getPageData(fromItem, order, limit));
  final response = await extractJSON(
      await get(baseApiUrl, TOKENS_URL, queryParameters: params));
  final TokensResponse tokensResponse =
      TokensResponse.fromJson(json.decode(response));
  return tokensResponse;
}

/// GET request to the /tokens/:tokenId endpoint. Returns a specific token
/// @param {int} tokenId - A token ID
/// @returns {object} Response data with a specific token
Future<String> getToken(int tokenId) async {
  return extractJSON(
      await get(baseApiUrl, TOKENS_URL + '/' + tokenId.toString()));
}

/// GET request to the /state endpoint.
/// @returns {object} Response data with the current state of the coordinator
Future<StateResponse> getState() async {
  final response = await extractJSON(await get(baseApiUrl, STATE_URL));
  final StateResponse stateResponse =
      StateResponse.fromJson(json.decode(response));
  return stateResponse;
  // Remove once hermez-node is ready
  /*state.network.nextForgers = [{
    coordinator: {
      URL: 'http://localhost:8086'
    }
  }];*/

  // state.withdrawalDelayer.emergencyMode = true
  // state.withdrawalDelayer.withdrawalDelay = 60
  // state.rollup.buckets[0].withdrawals = 0
}

/// GET request to the /batches endpoint. Returns a filtered list of batches
/// @param {String} forgerAddr - Filter by forger address
/// @param {int} slotNum - A specific slot number
/// @param {int} fromItem - Item from where to start the request
/// @returns {Object} Response data with a paginated list of batches
Future<String> getBatches(String forgerAddr, int slotNum, int fromItem) async {
  Map<String, String> params = {};
  params.putIfAbsent(
      'forgerAddr', () => forgerAddr.isNotEmpty ? forgerAddr : '');
  params.putIfAbsent('slotNum', () => slotNum > 0 ? slotNum.toString() : '');
  params.putIfAbsent('fromItem', () => fromItem > 0 ? fromItem.toString() : '');

  return extractJSON(
      await get(baseApiUrl, BATCHES_URL, queryParameters: params));
}

/// GET request to the /batches/:batchNum endpoint. Returns a specific batch
/// @param {int} batchNum - Number of a specific batch
/// @returns {Object} Response data with a specific batch
Future<String> getBatch(int batchNum) async {
  return extractJSON(
      await get(baseApiUrl, BATCHES_URL + '/' + batchNum.toString()));
}

/// GET request to the /coordinators/:bidderAddr endpoint. Returns a specific coordinator information
/// @param {String} forgerAddr - A coordinator forger address
/// @param {String} bidderAddr - A coordinator bidder address
/// @returns {Object} Response data with a specific coordinator
Future<String> getCoordinators(String forgerAddr, String bidderAddr) async {
  Map<String, String> params = {};
  params.putIfAbsent(
      'forgerAddr', () => forgerAddr.isNotEmpty ? forgerAddr : '');
  params.putIfAbsent(
      'bidderAddr', () => bidderAddr.isNotEmpty ? bidderAddr : '');

  return extractJSON(
      await get(baseApiUrl, COORDINATORS_URL, queryParameters: params));
}

/// GET request to the /slots/:slotNum endpoint. Returns the information for a specific slot
/// @param {int} slotNum - The nunmber of a slot
/// @returns {Object} Response data with a specific slot
Future<String> getSlot(int slotNum) async {
  return extractJSON(
      await get(baseApiUrl, SLOTS_URL + '/' + slotNum.toString()));
}

/// GET request to the /bids endpoint. Returns a list of bids
/// @param {int} slotNum - Filter by slot
/// @param {String} bidderAddr - Filter by coordinator
/// @param {int} fromItem - Item from where to start the request
/// @returns {Object} Response data with the list of slots
Future<String> getBids(int slotNum, String bidderAddr, int fromItem) async {
  Map<String, String> params = {};
  params.putIfAbsent('slotNum', () => slotNum > 0 ? slotNum.toString() : '');
  params.putIfAbsent(
      'bidderAddr', () => bidderAddr.isNotEmpty ? bidderAddr : '');
  params.putIfAbsent('fromItem', () => fromItem > 0 ? fromItem.toString() : '');

  return extractJSON(await get(baseApiUrl, BIDS_URL, queryParameters: params));
}

/// POST request to the /account-creation-authorization endpoint. Sends an authorization to the coordinator to register token accounts on their behalf
/// @param {String} hezEthereumAddress - The Hermez Ethereum address of the account that makes the authorization
/// @param {String} bJJ - BabyJubJub address of the account that makes the authorization
/// @param {String} signature - The signature of the request
/// @returns {Object} Response data
Future<http.Response> postCreateAccountAuthorization(
    String hezEthereumAddress, String bJJ, String signature) async {
  Map<String, String> params = {};
  params.putIfAbsent('hezEthereumAddress',
      () => hezEthereumAddress.isNotEmpty ? hezEthereumAddress : '');
  params.putIfAbsent('bJJ', () => bJJ.isNotEmpty ? bJJ : '');
  params.putIfAbsent('signature', () => signature.isNotEmpty ? signature : '');
  return await post(baseApiUrl, ACCOUNT_CREATION_AUTH_URL, body: params);
}
