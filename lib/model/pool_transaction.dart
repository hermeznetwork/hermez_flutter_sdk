import 'package:hermez_sdk/model/token.dart';

class PoolTransaction {
  final String? id;
  final String? type;
  final String? fromAccountIndex;
  final String? fromBJJ;
  final String? fromHezEthereumAddress;
  final String? toAccountIndex;
  final String? toBjj;
  final String? toHezEthereumAddress;
  final String? amount;
  final int? fee;
  final int? nonce;
  final String? requestAmount;
  final int? requestFee;
  final String? requestFromAccountIndex;
  final String? requestNonce;
  final String? requestToAccountIndex;
  final String? requestToBJJ;
  final String? requestToHezEthereumAddress;
  final String? requestTokenId;
  final String? signature;
  final String? state;
  final String? timestamp;

  final String? info;
  final Token? token;

  PoolTransaction(
      {this.amount,
      this.fee,
      this.fromAccountIndex,
      this.fromBJJ,
      this.fromHezEthereumAddress,
      this.id,
      this.info,
      this.nonce,
      this.requestAmount,
      this.requestFee,
      this.requestFromAccountIndex,
      this.requestNonce,
      this.requestToAccountIndex,
      this.requestToBJJ,
      this.requestToHezEthereumAddress,
      this.requestTokenId,
      this.signature,
      this.state,
      this.timestamp,
      this.toAccountIndex,
      this.toBjj,
      this.toHezEthereumAddress,
      this.token,
      this.type});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [PoolTransaction]
  factory PoolTransaction.fromJson(Map<String, dynamic> json) {
    Token token = Token.fromJson(json['token']);
    return PoolTransaction(
      amount: json['amount'],
      fee: json['fee'],
      fromAccountIndex: json['fromAccountIndex'],
      fromBJJ: json['fromBJJ'],
      fromHezEthereumAddress: json['fromHezEthereumAddress'],
      id: json['id'],
      info: json['info'],
      nonce: json['nonce'],
      requestAmount: json['requestAmount'],
      requestFee: json['requestFee'],
      requestFromAccountIndex: json['requestFromAccountIndex'],
      requestNonce: json['requestNonce'],
      requestToAccountIndex: json['requestToAccountIndex'],
      requestToBJJ: json['requestToBJJ'],
      requestToHezEthereumAddress: json['requestToHezEthereumAddress'],
      requestTokenId: json['requestTokenId'],
      signature: json['signature'],
      state: json['state'],
      timestamp: json['timestamp'],
      toAccountIndex: json['toAccountIndex'],
      toBjj: json['toBjj'],
      toHezEthereumAddress: json['toHezEthereumAddress'],
      token: token,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'fee': fee,
        'fromAccountIndex': fromAccountIndex,
        'fromBJJ': fromBJJ,
        'fromHezEthereumAddress': fromHezEthereumAddress,
        'id': id,
        'info': info,
        'nonce': nonce,
        'requestAmount': requestAmount,
        'requestFee': requestFee,
        'requestFromAccountIndex': requestFromAccountIndex,
        'requestNonce': requestNonce,
        'requestToAccountIndex': requestToAccountIndex,
        'requestToBJJ': requestToBJJ,
        'requestToHezEthereumAddress': requestToHezEthereumAddress,
        'requestTokenId': requestTokenId,
        'signature': signature,
        'state': state,
        'timestamp': timestamp,
        'toAccountIndex': toAccountIndex,
        'toBjj': toBjj,
        'toHezEthereumAddress': toHezEthereumAddress,
        'token': token!.toJson(),
        'type': type
      };
}
