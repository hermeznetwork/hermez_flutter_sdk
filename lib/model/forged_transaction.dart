import 'package:hermez_sdk/model/token.dart';

import 'l1info.dart';
import 'l2info.dart';

class ForgedTransaction {
  final L1Info l1info;
  final String L1orL2;
  final L2Info l2info;
  final String amount;
  final int batchNum;
  final String fromAccountIndex;
  final String fromBJJ;
  final String fromHezEthereumAddress;
  final double historicUSD;
  final String id;
  final int itemId;
  final int position;
  final String timestamp;
  final String toAccountIndex;
  final String toBJJ;
  final String toHezEthereumAddress;
  final Token token;
  final String type;
  final String hash;

  ForgedTransaction(
      {this.l1info,
      this.L1orL2,
      this.l2info,
      this.amount,
      this.batchNum,
      this.fromAccountIndex,
      this.fromBJJ,
      this.fromHezEthereumAddress,
      this.historicUSD,
      this.id,
      this.itemId,
      this.position,
      this.timestamp,
      this.toAccountIndex,
      this.toBJJ,
      this.toHezEthereumAddress,
      this.token,
      this.type,
      this.hash});

  factory ForgedTransaction.fromJson(Map<String, dynamic> json) {
    L1Info l1Info = L1Info.fromJson(json['L1Info']);
    L2Info l2Info = L2Info.fromJson(json['L2Info']);
    Token token = Token.fromJson(json['token']);
    return ForgedTransaction(
      l1info: l1Info,
      L1orL2: json['L1orL2'],
      l2info: l2Info,
      amount: json['amount'],
      batchNum: json['batchNum'],
      fromAccountIndex: json['fromAccountIndex'],
      fromBJJ: json['fromBJJ'],
      fromHezEthereumAddress: json['fromHezEthereumAddress'],
      historicUSD: double.tryParse(json['historicUSD'].toString()) ?? 0.0,
      id: json['id'],
      itemId: json['itemId'],
      position: json['position'],
      timestamp: json['timestamp'],
      toAccountIndex: json['toAccountIndex'],
      toBJJ: json['toBJJ'],
      toHezEthereumAddress: json['toHezEthereumAddress'],
      token: token,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'l1info': l1info.toJson(),
        'L1orL2': L1orL2,
        'l2info': l2info.toJson(),
        'amount': amount,
        'batchNum': batchNum,
        'fromAccountIndex': fromAccountIndex,
        'fromBJJ': fromBJJ,
        'fromHezEthereumAddress': fromHezEthereumAddress,
        'historicUSD': historicUSD,
        'id': id,
        'itemId': itemId,
        'position': position,
        'timestamp': timestamp,
        'toAccountIndex': toAccountIndex,
        'toBJJ': toBJJ,
        'toHezEthereumAddress': toHezEthereumAddress,
        'token': token.toJson(),
        'type': type
      };
}
