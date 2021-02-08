import 'l1info.dart';
import 'l2info.dart';

class ForgedTransaction {
  final String L1orL2;
  final String id;
  final String type;
  final int position;
  final String fromAccountIndex;
  final String toAccountIndex;
  final String amount;
  final int batchNum;
  final int tokenId;
  final String tokenSymbol;
  final String timestamp;
  final L1Info l1info;
  final L2Info l2info;

  ForgedTransaction({this.L1orL2, this.id, this.type, this.position, this.fromAccountIndex, this.toAccountIndex,
    this.amount, this.batchNum, this.tokenId, this.tokenSymbol, this.timestamp, this.l1info, this.l2info});

  factory ForgedTransaction.fromJson(Map<String, dynamic> json) {
    return ForgedTransaction(
        L1orL2: json['L1orL2'],
        id: json['id'],
        type: json['type'],
        position: json['position'],
        fromAccountIndex: json['fromAccountIndex'],
        toAccountIndex: json['toAccountIndex'],
        amount: json['amount'],
        batchNum: json['batchNum'],
        tokenId: json['tokenId'],
        tokenSymbol: json['tokenSymbol'],
        timestamp: json['timestamp'],
        l1info: json['L1Info'],
        l2info: json['L2Info'],

    );
  }

  Map<String, dynamic> toJson() => {
    'L1orL2': L1orL2,
    'id': id,
    'type': type,
    'position': position,
    'fromAccountIndex': fromAccountIndex,
    'toAccountIndex': toAccountIndex,
    'amount': amount,
    'batchNum': batchNum,
    'tokenId': tokenId,
    'tokenSymbol': tokenSymbol,
    'timestamp': timestamp,
    'L1Info': l1info,
    'L2Info': l2info
  };

}
