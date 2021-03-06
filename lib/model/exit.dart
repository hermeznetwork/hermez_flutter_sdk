import 'merkle_proof.dart';
import 'token.dart';

class Exit {
  final int batchNum;
  final String accountIndex;
  final int itemId;
  final MerkleProof merkleProof;
  final String balance;
  final int instantWithdraw;
  final String delayedWithdrawRequest;
  final int delayedWithdraw;
  final Token token;
  final String bjj;
  final String hezEthereumAddress;

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

  Map<String, dynamic> toJson() => {
        'batchNum': batchNum,
        'accountIndex': accountIndex,
        'itemId': itemId,
        'merkleProof': merkleProof.toJson(),
        'balance': balance,
        'instantWithdrawn': instantWithdraw,
        'delayedWithdrawRequest': delayedWithdrawRequest,
        'delayedWithdrawn': delayedWithdraw,
        'token': token.toJson(),
        'bjj': bjj,
        'hezEthereumAddress': hezEthereumAddress
      };
}
