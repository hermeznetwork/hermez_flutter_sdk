import 'package:hermez_sdk/model/account.dart';

class AccountsResponse {
  final List<Account> accounts;
  final int pendingItems;

  AccountsResponse({this.accounts, this.pendingItems});

  factory AccountsResponse.fromJson(Map<String, dynamic> json) {
    List<Account> accounts = (json['accounts'] as List)
        ?.map((item) => Account.fromJson(item))
        ?.toList();
    return AccountsResponse(
        accounts: accounts, pendingItems: json['pendingItems']);
  }

  Map<String, dynamic> toJson() => {
        'accounts': accounts,
        'pendingItems': pendingItems,
      };
}
