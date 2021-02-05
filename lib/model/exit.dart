import 'merkle_proof.dart';
import 'token.dart';

class Exit {
  final int batchNum;
  final String accountIndex;
  final int itemId;
  final MerkleProof merkleProof;
  final String balance;
  final int instantWithdrawn;
  final String delayedWithdrawRequest;
  final int delayedWithdrawn;
  final Token token;

  Exit(
      {this.batchNum,
      this.accountIndex,
      this.itemId,
      this.merkleProof,
      this.balance,
      this.instantWithdrawn,
      this.delayedWithdrawRequest,
      this.delayedWithdrawn,
      this.token});

  factory Exit.fromJson(Map<String, dynamic> json) {
    Token token = Token.fromJson(json['token']);
    MerkleProof merkleProof = MerkleProof.fromJson(json['merkleProof']);
    return Exit(
        batchNum: json['batchNum'],
        accountIndex: json['accountIndex'],
        itemId: json['itemId'],
        merkleProof: merkleProof,
        balance: json['balance'],
        instantWithdrawn: json['instantWithdrawn'],
        delayedWithdrawRequest: json['delayedWithdrawRequest'],
        delayedWithdrawn: json['delayedWithdrawn'],
        token: token);
  }

  Map<String, dynamic> toJson() => {
        'batchNum': batchNum,
        'accountIndex': accountIndex,
        'itemId': itemId,
        'merkleProof': merkleProof.toJson(),
        'balance': balance,
        'instantWithdrawn': instantWithdrawn,
        'delayedWithdrawRequest': delayedWithdrawRequest,
        'delayedWithdrawn': delayedWithdrawn,
        'token': token.toJson()
      };
}
