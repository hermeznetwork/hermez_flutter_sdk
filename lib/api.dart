import 'dart:convert';

import 'package:hermez_sdk/http.dart' show extractJSON, get, post;
import 'package:hermez_sdk/model/coordinator.dart';
import 'package:hermez_sdk/model/coordinators_response.dart';
import 'package:http/http.dart' as http;

import 'addresses.dart' show isHermezEthereumAddress, isHermezBjjAddress;
import 'constants.dart' show DEFAULT_PAGE_SIZE;
import 'model/account.dart';
import 'model/accounts_response.dart';
import 'model/create_account_authorization.dart';
import 'model/exit.dart';
import 'model/exits_response.dart';
import 'model/forged_transaction.dart';
import 'model/forged_transactions_response.dart';
import 'model/pool_transaction.dart';
import 'model/state_response.dart';
import 'model/token.dart';
import 'model/tokens_response.dart';

var baseApiUrl = '';

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
///
/// @param [int] fromItem - Item from where to start the request
/// @param [PaginationOrder] order - order of pagination selected
/// @param [int] limit - number of items to receive with the request
/// @returns [Map<String, String>] Includes the values [fromItem] and [limit]
/// @private
Map<String, String> _getPageData(
    int fromItem, PaginationOrder order, int limit) {
  Map<String, String> params = {};
  if (fromItem > 0) {
    params.putIfAbsent('fromItem', () => fromItem.toString());
  }
  params.putIfAbsent('order', () => order.toString().split(".")[1]);
  params.putIfAbsent('limit', () => limit.toString());
  return params;
}

/// Sets the current coordinator API URL
///
/// @param [String] url - The currently forging Coordinator
void setBaseApiUrl(String url) {
  baseApiUrl = url;
}

/// Returns current coordinator API URL
///
/// @returns [String] The currently set Coordinator
String getBaseApiUrl() {
  return baseApiUrl;
}

/// Makes sure a list of next forgers includes the base API URL
///
/// @param [Set<String>] nextForgerUrls - Set of forger URLs that may or may not include the base API URL
/// @returns [Set<String>] nextForgerUrls - Array of next forgers that definitely includes the base API URL
Set<String> getForgerUrls(Set<String> nextForgerUrls) {
  return nextForgerUrls.contains(baseApiUrl)
      ? nextForgerUrls
      : [...nextForgerUrls, baseApiUrl].toSet();
}

/// Checks a list of responses from one same POST request to different coordinators
/// If all responses are errors, throw the error
/// If at least 1 was successful, return it
///
/// @param [Set<http.Response>] responsesArray - An set of responses, including errors
/// @returns [Set<http.Response>] response
/// @throws Error
http.Response filterResponses(Set<http.Response> responsesArray) {
  Set<http.Response> invalidResponses = Set.from(responsesArray);
  invalidResponses.removeWhere((res) => res.statusCode == 200);
  if (invalidResponses.length == responsesArray.length) {
    return responsesArray.first;
  } else {
    return responsesArray.firstWhere((res) => res.statusCode == 200);
  }
}

/// Fetches the URLs of the next forgers from the /state API
///
/// @returns [Set<String>] An set of URLs of the next forgers
Future<Set<String>> getNextForgerUrls() async {
  StateResponse coordinatorState = await getState();
  return coordinatorState.network!.nextForgers!
      .map((nextForger) =>
          nextForger.coordinator!.URL!.replaceFirst("https://", ""))
      .toSet();
}

/// GET request to the /accounts endpoint. Returns a list of token accounts associated to a Hermez address
///
/// @param [String] address - The account's address. It can be a Hermez Ethereum address or a Hermez BabyJubJub address
/// @param [List<int>] tokenIds - List of token Ids as registered in the network
/// @param optional [int] fromItem - Item from where to start the request
/// @param optional [PaginationOrder] order - order of pagination selected
/// @param optional [int] limit - number of items to receive with the request
/// @returns [AccountsResponse] Response data with filtered token accounts and pagination data
Future<AccountsResponse> getAccounts(String address, List<int> tokenIds,
    {int fromItem = 0,
    PaginationOrder order = PaginationOrder.ASC,
    int limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String?> params = {};
  if (isHermezEthereumAddress(address) && address.isNotEmpty)
    params.putIfAbsent('hezEthereumAddress', () => address);
  else if (isHermezBjjAddress(address) && address.isNotEmpty)
    params.putIfAbsent('BJJ', () => address);
  if (tokenIds.isNotEmpty)
    params.putIfAbsent('tokenIds', () => tokenIds.join(','));
  params.addAll(_getPageData(fromItem, order, limit));
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
///
/// @param [string] accountIndex - Account index in the format hez:DAI:4444
/// @returns [Account] Response data with the token account
Future<Account> getAccount(String accountIndex) async {
  final response = await get(baseApiUrl, ACCOUNTS_URL + '/' + accountIndex);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final Account accountResponse = Account.fromJson(json.decode(jsonResponse));
    return accountResponse;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /transactions-histroy endpoint. Returns a list of forged transaction based on certain filters
///
/// @param [String] address - Filter by the address that sent or received the transactions. It can be a Hermez Ethereum address or a Hermez BabyJubJub address
/// @param [List<int>] tokenIds - List of token IDs as registered in the network
/// @param [int] batchNum - Filter by batch number
/// @param [String] accountIndex - Filter by an account index that sent or received the transactions
/// @param optional [int] fromItem - Item from where to start the request
/// @param optional [PaginationOrder] order - order of pagination selected
/// @param optional [int] limit - number of items to receive with the request
/// @returns [ForgedTransactionsResponse] Response data with filtered transactions and pagination data
Future<ForgedTransactionsResponse> getTransactions(
    {String address = "",
    List<int>? tokenIds,
    int batchNum = 0,
    String accountIndex = "",
    int fromItem = 0,
    PaginationOrder order = PaginationOrder.ASC,
    int limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String> params = {};
  if (address.isNotEmpty && isHermezEthereumAddress(address))
    params.putIfAbsent('hezEthereumAddress', () => address);
  if (address.isNotEmpty && isHermezBjjAddress(address))
    params.putIfAbsent('BJJ', () => address);
  if (tokenIds != null && tokenIds.isNotEmpty)
    params.putIfAbsent('tokenIds', () => tokenIds.join(','));
  if (batchNum > 0) {
    params.putIfAbsent('batchNum', () => batchNum.toString());
  }
  if (accountIndex.isNotEmpty) {
    params.putIfAbsent('accountIndex', () => accountIndex);
  }
  params.addAll(_getPageData(fromItem, order, limit));
  final response =
      await get(baseApiUrl, TRANSACTIONS_HISTORY_URL, queryParameters: params);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final ForgedTransactionsResponse forgedTransactionsResponse =
        ForgedTransactionsResponse.fromJson(json.decode(jsonResponse));
    return forgedTransactionsResponse;
  } else {
    throw ('Error: ${response.body}');
  }
}

/// GET request to the /transactions-history/:transactionId endpoint. Returns a specific forged transaction
///
/// @param [String] transactionId - The Id for the specific transaction
/// @returns [ForgedTransaction] Response data with the transaction
Future<ForgedTransaction?> getHistoryTransaction(String transactionId) async {
  final response =
      await get(baseApiUrl, TRANSACTIONS_HISTORY_URL + '/' + transactionId);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final ForgedTransaction forgedTransaction =
        ForgedTransaction.fromJson(json.decode(jsonResponse));
    return forgedTransaction;
  } else {
    return null;
  }
}

/// GET request to the /transactions-pool/:transactionId endpoint. Returns a specific unforged transaction
///
/// @param [String] transactionId - The Id for the specific transaction
/// @returns [PoolTransaction] Response data with the unforged transaction
Future<PoolTransaction> getPoolTransaction(String transactionId) async {
  final response =
      await get(baseApiUrl, TRANSACTIONS_POOL_URL + '/' + transactionId);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final PoolTransaction poolTransaction =
        PoolTransaction.fromJson(json.decode(jsonResponse));
    return poolTransaction;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// POST request to the /transaction-pool endpoint. Sends an L2 transaction to the network
///
/// @param [Map<String, dynamic>] transaction - Transaction data returned by TxUtils.generateL2Transaction
/// @returns [Response] Transaction id
Future<http.Response> postPoolTransaction(
    Map<String, dynamic> transaction) async {
  Set<String> nextForgerUrls = await getNextForgerUrls();
  Set<String> forgerUrls = getForgerUrls(nextForgerUrls);
  Set<http.Response> responsesArray = Set();
  for (String apiUrl in forgerUrls) {
    http.Response response =
        await post(apiUrl, TRANSACTIONS_POOL_URL, body: transaction);
    responsesArray.add(response);
  }
  return filterResponses(responsesArray);
}

/// GET request to the /exits endpoint. Returns a list of exits based on certain filters
///
/// @param [String] address - Filter by the address associated to the exits. It can be a Hermez Ethereum address or a Hermez BabyJubJub address
/// @param [bool] onlyPendingWithdraws - Filter by exits that still haven't been withdrawn
/// @param [int] tokenId - Filter by token Id
/// @returns [ExitsResponse] Response data with the list of exits
Future<ExitsResponse> getExits(
    String address, bool onlyPendingWithdraws, int tokenId) async {
  Map<String, String?> params = {};
  if (isHermezEthereumAddress(address) && address.isNotEmpty)
    params.putIfAbsent('hezEthereumAddress', () => address);
  if (isHermezBjjAddress(address) && address.isNotEmpty)
    params.putIfAbsent('BJJ', () => address);
  params.putIfAbsent(
      'onlyPendingWithdraws', () => onlyPendingWithdraws.toString());
  if (tokenId >= 0) {
    params.putIfAbsent('tokenId', () => tokenId.toString());
  }
  final response = await get(baseApiUrl, EXITS_URL, queryParameters: params);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final ExitsResponse exitsResponse =
        ExitsResponse.fromJson(json.decode(jsonResponse));
    return exitsResponse;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /exits/:batchNum/:accountIndex endpoint. Returns a specific exit
///
/// @param [int] batchNum - Filter by an exit in a specific batch number
/// @param [String] accountIndex - Filter by an exit associated to an account index
/// @returns [Exit] Response data with the specific exit
Future<Exit> getExit(int batchNum, String accountIndex) async {
  final response = await get(
      baseApiUrl, EXITS_URL + '/' + batchNum.toString() + '/' + accountIndex);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final Exit exitResponse = Exit.fromJson(json.decode(jsonResponse));
    return exitResponse;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /tokens endpoint. Returns a list of token data
///
/// @param optional [List<int>?] tokenIds - A list of token Ids
/// @param optional [int] fromItem - Item from where to start the request
/// @param optional [PaginationOrder] order - order of pagination selected
/// @param optional [int] limit - number of items to receive with the request
/// @returns [TokensResponse] Response data with the list of tokens
Future<TokensResponse> getTokens(
    {List<int>? tokenIds,
    int fromItem = 0,
    order = PaginationOrder.ASC,
    limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String> params = {};
  if (tokenIds != null && tokenIds.isNotEmpty)
    params.putIfAbsent(
        'ids', () => tokenIds.isNotEmpty ? tokenIds.join(',') : '');
  params.addAll(_getPageData(fromItem, order, limit));
  final response = await
      await get(baseApiUrl, TOKENS_URL, queryParameters: params);
  if (response != null && response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final tokensResponse =
    TokensResponse.fromJson(json.decode(jsonResponse));
    return tokensResponse;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /tokens/:tokenId endpoint. Returns a specific token
///
/// @param [int] tokenId - A token Id
/// @returns [Token] Response data with a specific token
Future<Token> getToken(int tokenId) async {
  final response = await get(baseApiUrl, TOKENS_URL + '/' + tokenId.toString());
  if (response != null && response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final tokenResponse = Token.fromJson(json.decode(jsonResponse));
    return tokenResponse;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /state endpoint.
///
/// @returns [StateResponse] Response data with the current state of the coordinator
Future<StateResponse> getState() async {
  final response = await extractJSON(await get(baseApiUrl, STATE_URL));
  final StateResponse stateResponse =
      StateResponse.fromJson(json.decode(response));
  return stateResponse;
}

/// GET request to the /batches endpoint. Returns a filtered list of batches
///
/// @param [String] forgerAddr - Filter by forger address
/// @param [int] slotNum - A specific slot number
/// @param [int] fromItem - Item from where to start the request
/// @returns [String] Response data with a paginated list of batches
Future<String> getBatches(String forgerAddr, int slotNum, int fromItem) async {
  Map<String, String> params = {};
  params.putIfAbsent(
      'forgerAddr', () => forgerAddr.isNotEmpty ? forgerAddr : '');
  params.putIfAbsent('slotNum', () => slotNum > 0 ? slotNum.toString() : '');
  params.putIfAbsent('fromItem', () => fromItem > 0 ? fromItem.toString() : '');

  return extractJSON(
      await get(baseApiUrl, BATCHES_URL, queryParameters: params));
  // TODO create ResponseObject
}

/// GET request to the /batches/:batchNum endpoint. Returns a specific batch
///
/// @param [int] batchNum - Number of a specific batch
/// @returns [String] Response data with a specific batch
Future<String> getBatch(int batchNum) async {
  return extractJSON(
      await get(baseApiUrl, BATCHES_URL + '/' + batchNum.toString()));
  // TODO create ResponseObject
}

/// GET request to the /coordinators/:bidderAddr endpoint. Returns a specific coordinator information
///
/// @param [String] forgerAddr - A coordinator forger address
/// @param [String] bidderAddr - A coordinator bidder address
/// @param optional [int] fromItem - Item from where to start the request
/// @param optional [PaginationOrder] order - order of pagination selected
/// @param optional [int] limit - number of items to receive with the request
/// @returns [List<Coordinator>] Response data with a specific coordinator
Future<List<Coordinator>?> getCoordinators(String forgerAddr, String bidderAddr,
    {int fromItem = 0,
    PaginationOrder order = PaginationOrder.ASC,
    int limit = DEFAULT_PAGE_SIZE}) async {
  Map<String, String> params = {};
  params.putIfAbsent(
      'forgerAddr', () => forgerAddr.isNotEmpty ? forgerAddr : '');
  params.putIfAbsent(
      'bidderAddr', () => bidderAddr.isNotEmpty ? bidderAddr : '');
  params.addAll(_getPageData(fromItem, order, limit));

  final response =
      await get(baseApiUrl, COORDINATORS_URL, queryParameters: params);
  if (response.statusCode == 200) {
    final jsonResponse = await extractJSON(response);
    final coordinatorsResponse =
        CoordinatorsResponse.fromJson(json.decode(jsonResponse));
    return coordinatorsResponse.coordinators;
  } else {
    throw ('Error: $response.statusCode');
  }
}

/// GET request to the /slots/:slotNum endpoint. Returns the information for a specific slot
/// @param {int} slotNum - The nunmber of a slot
/// @returns {Object} Response data with a specific slot
Future<String> getSlot(int slotNum) async {
  return extractJSON(
      await get(baseApiUrl, SLOTS_URL + '/' + slotNum.toString()));
  // TODO create ResponseObject
}

/// GET request to the /bids endpoint. Returns a list of bids
///
/// @param [int] slotNum - Filter by slot
/// @param [String] bidderAddr - Filter by coordinator
/// @param [int] fromItem - Item from where to start the request
/// @returns [String] Response data with the list of slots
Future<String> getBids(int slotNum, String bidderAddr, int fromItem) async {
  Map<String, String> params = {};
  params.putIfAbsent('slotNum', () => slotNum > 0 ? slotNum.toString() : '');
  params.putIfAbsent(
      'bidderAddr', () => bidderAddr.isNotEmpty ? bidderAddr : '');
  params.putIfAbsent('fromItem', () => fromItem > 0 ? fromItem.toString() : '');

  return extractJSON(await get(baseApiUrl, BIDS_URL, queryParameters: params));
  // TODO create ResponseObject
}

/// POST request to the /account-creation-authorization endpoint.
/// Sends an authorization to the coordinator to register token accounts on their behalf
///
/// @param [String] hezEthereumAddress - The Hermez Ethereum address of the account that makes the authorization
/// @param [String] bjj - BabyJubJub address of the account that makes the authorization
/// @param [String] signature - The signature of the request
/// @returns {Response} Response data
Future<http.Response?> postCreateAccountAuthorization(
    String hezEthereumAddress, String bjj, String signature) async {
  Map<String, String?> params = {};
  params.putIfAbsent('hezEthereumAddress',
      () => hezEthereumAddress.isNotEmpty ? hezEthereumAddress : '');
  params.putIfAbsent('bjj', () => bjj.isNotEmpty ? bjj : '');
  params.putIfAbsent('signature', () => signature.isNotEmpty ? signature : '');
  try {
    return await post(baseApiUrl, ACCOUNT_CREATION_AUTH_URL, body: params);
  } catch (e) {
    return null;
  }
}

/// GET request to the /account-creation-authorization endpoint.
///
/// @param [String] hezEthereumAddress - The Hermez Ethereum address of the account that makes the authorization
/// @returns {CreateAccountAuthorization} Response data
Future<CreateAccountAuthorization?> getCreateAccountAuthorization(
    String hezEthereumAddress) async {
  try {
    final response = await get(
        baseApiUrl, ACCOUNT_CREATION_AUTH_URL + '/' + hezEthereumAddress,
        queryParameters: null);
    if (response.statusCode == 200) {
      final jsonResponse = await extractJSON(response);
      final authorizationResponse =
          CreateAccountAuthorization.fromJson(json.decode(jsonResponse));
      return authorizationResponse;
    } else {
      throw ('Error: $response.statusCode');
    }
  } catch (e) {
    return null;
  }
}
