import 'package:hermez_plugin/http.dart' show extractJSON, get, post;

const baseApiUrl = 'http://167.71.59.190:4010';

const REGISTER_AUTH_URL = "/account-creation-authorization";
const ACCOUNTS_URL = "/accounts";
const EXITS_URL = "/exits";
const STATE_URL = "/state";

const TRANSACTIONS_POOL_URL = "/transactions-pool";
const TRANSACTIONS_HISTORY_URL = "/transactions-history";

const TOKENS_URL = "/tokens";
const RECOMMENDED_FEES_URL = "/recommendedFee";
const COORDINATORS_URL = "/coordinators";

Future<String> getAccounts(
    String hermezEthereumAddress, List<dynamic> tokenIds) async {
  Map<String, String> params = {
    "hermezEthereumAddress":
        hermezEthereumAddress.isNotEmpty ? hermezEthereumAddress : '',
    "tokenIds": tokenIds.isNotEmpty ? tokenIds.join(',') : ''
  };
  return extractJSON(get(baseApiUrl, ACCOUNTS_URL, queryParameters: params));
}

Future<String> getAccount(int accountIndex) async {
  return extractJSON(
      get(baseApiUrl, ACCOUNTS_URL + '/' + accountIndex.toString()));
}

Future<String> getTransactions(int accountIndex) async {
  Map<String, String> params = {
    'accountIndex': accountIndex > 0 ? accountIndex.toString() : ''
  };
  return extractJSON(
      get(baseApiUrl, TRANSACTIONS_HISTORY_URL, queryParameters: params));
}

Future<String> getHistoryTransaction(int transactionId) async {
  return extractJSON(get(
      baseApiUrl, TRANSACTIONS_HISTORY_URL + '/' + transactionId.toString()));
}

Future<String> getPoolTransaction(int transactionId) async {
  return extractJSON(get(
      baseApiUrl, TRANSACTIONS_HISTORY_URL + '/' + transactionId.toString()));
}

Future<String> postPoolTransaction(dynamic transaction) async {
  return extractJSON(
      post(baseApiUrl, TRANSACTIONS_POOL_URL, body: transaction));
}

Future<String> getExits() async {
  return extractJSON(get(baseApiUrl, EXITS_URL));
}

Future<String> getExit(int batchNum, int accountIndex) async {
  return extractJSON(get(baseApiUrl,
      EXITS_URL + '/' + batchNum.toString() + '/' + accountIndex.toString()));
}

Future<String> getTokens(tokenIds) async {
  Map<String, String> params = {
    "tokenIds": tokenIds.isNotEmpty ? tokenIds.join(',') : ''
  };

  return extractJSON(get(baseApiUrl, TOKENS_URL, queryParameters: params));
}

Future<String> getToken(int tokenId) async {
  return extractJSON(get(baseApiUrl, TOKENS_URL + '/' + tokenId.toString()));
}

Future<String> getState() async {
  return extractJSON(get(baseApiUrl, STATE_URL));
}