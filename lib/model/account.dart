import 'token.dart';

class Account {
  final String? accountIndex;
  final String? balance;
  final String? bjj;
  final String? hezEthereumAddress;
  final int? itemId;
  final int? nonce;
  final Token? token;

  Account(
      {this.accountIndex,
      this.balance,
      this.bjj,
      this.hezEthereumAddress,
      this.itemId,
      this.nonce,
      this.token});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Account]
  factory Account.fromJson(Map<String, dynamic> json) {
    Token token = Token.fromJson(json['token']);
    return Account(
        accountIndex: json['accountIndex'],
        balance: json['balance'],
        bjj: json['bjj'],
        hezEthereumAddress: json['hezEthereumAddress'],
        itemId: json['itemId'],
        nonce: json['nonce'],
        token: token);
  }

  Map<String, dynamic> toJson() => {
        'accountIndex': accountIndex,
        'balance': balance,
        'bjj': bjj,
        'hezEthereumAddress': hezEthereumAddress,
        'itemId': itemId,
        'nonce': nonce,
        'token': token!.toJson(),
      };
}
