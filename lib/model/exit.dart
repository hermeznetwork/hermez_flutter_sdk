import 'package:hermez_sdk/model/pool_transaction.dart';

import 'merkle_proof.dart';
import 'token.dart';

class Exit {
  final int? batchNum;
  final String? accountIndex;
  final int? itemId;
  final MerkleProof? merkleProof;
  String? balance;
  final int? instantWithdraw;
  int? delayedWithdrawRequest;
  final int? delayedWithdraw;
  final Token? token;
  final String? bjj;
  final String? hezEthereumAddress;

  Exit(
      {this.batchNum,
      this.accountIndex,
      this.itemId,
      this.merkleProof,
      this.balance,
      this.instantWithdraw,
      this.delayedWithdrawRequest,
      this.delayedWithdraw,
      this.token,
      this.bjj,
      this.hezEthereumAddress});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Exit]
  factory Exit.fromJson(Map<String, dynamic> json) {
    Token token = Token.fromJson(json['token']);
    MerkleProof merkleProof = MerkleProof.fromJson(json['merkleProof']);
    return Exit(
        batchNum: json['batchNum'],
        accountIndex: json['accountIndex'],
        itemId: json['itemId'],
        merkleProof: merkleProof,
        balance: json['balance'],
        instantWithdraw: json['instantWithdraw'],
        delayedWithdrawRequest: json['delayedWithdrawRequest'],
        delayedWithdraw: json['delayedWithdraw'],
        token: token,
        bjj: json['bjj'],
        hezEthereumAddress: json['hezEthereumAddress']);
  }

  factory Exit.fromL1Transaction(dynamic transaction) {
    Token token = Token.fromJson(transaction['token']);
    //MerkleProof merkleProof = MerkleProof.fromJson(json['merkleProof']);
    return Exit(
      //batchNum: json['batchNum'],
      accountIndex: transaction['accountIndex'],
      //itemId: transaction.id,
      //merkleProof: merkleProof,
      balance: transaction['amount'].toString(),
      //instantWithdraw: json['instantWithdraw'],
      //delayedWithdrawRequest: json['delayedWithdrawRequest'],
      //delayedWithdraw: json['delayedWithdraw'],
      token: token,
      //bjj: json['bjj'],
      //hezEthereumAddress: json['hezEthereumAddress']
    );
  }

  factory Exit.fromTransaction(PoolTransaction transaction) {
    //Token token = Token.fromJson(json['token']);
    //MerkleProof merkleProof = MerkleProof.fromJson(json['merkleProof']);
    return Exit(
      //batchNum: json['batchNum'],
      accountIndex: transaction.fromAccountIndex,
      //itemId: transaction.id,
      //merkleProof: merkleProof,
      balance: transaction.amount,
      //instantWithdraw: json['instantWithdraw'],
      //delayedWithdrawRequest: json['delayedWithdrawRequest'],
      //delayedWithdraw: json['delayedWithdraw'],
      token: transaction.token,
      //bjj: json['bjj'],
      //hezEthereumAddress: json['hezEthereumAddress']
    );
  }

  Map<String, dynamic> toJson() => {
        'batchNum': batchNum,
        'accountIndex': accountIndex,
        'itemId': itemId,
        'merkleProof': merkleProof!.toJson(),
        'balance': balance,
        'instantWithdrawn': instantWithdraw,
        'delayedWithdrawRequest': delayedWithdrawRequest,
        'delayedWithdrawn': delayedWithdraw,
        'token': token!.toJson(),
        'bjj': bjj,
        'hezEthereumAddress': hezEthereumAddress
      };
}
