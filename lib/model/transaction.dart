class Transaction {
  final String id;
  final String type;
  final String fromAccountIndex;
  final String toAccountIndex;
  final String toEthereumAddress;
  final String toBjj;
  final int tokenId;
  final int amount;
  final int fee;
  final int nonce;
  final String state;
  final String signature;
  final String timestamp;
  final int batchNum;
  final String rqFromAccountIndex;
  final String rqToAccountIndex;
  final String rqToEthereumAddress;
  final String rqToBJJ;
  final int rqTokenId;
  final String rqAmount;
  final int rqFee;
  final int rqNonce;
  final String tokenSymbol;

  Transaction(
      {this.id,
      this.type,
      this.fromAccountIndex,
      this.toAccountIndex,
      this.toEthereumAddress,
      this.toBjj,
      this.tokenId,
      this.amount,
      this.fee,
      this.nonce,
      this.state,
      this.signature,
      this.timestamp,
      this.batchNum,
      this.rqFromAccountIndex,
      this.rqToAccountIndex,
      this.rqToEthereumAddress,
      this.rqToBJJ,
      this.rqTokenId,
      this.rqAmount,
      this.rqFee,
      this.rqNonce,
      this.tokenSymbol});

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      fromAccountIndex: json['fromAccountIndex'],
      toAccountIndex: json['toAccountIndex'],
      toEthereumAddress: json['toEthereumAddress'],
      toBjj: json['toBjj'],
      tokenId: json['tokenId'],
      amount: json['amount'],
      fee: json['fee'],
      nonce: json['nonce'],
      state: json['state'],
      signature: json['signature'],
      timestamp: json['timestamp'],
      batchNum: json['batchNum'],
      rqFromAccountIndex: json['rqFromAccountIndex'],
      rqToAccountIndex: json['rqToAccountIndex'],
      rqToEthereumAddress: json['rqToEthereumAddress'],
      rqToBJJ: json['rqToBJJ'],
      rqTokenId: json['rqTokenId'],
      rqAmount: json['rqAmount'],
      rqFee: json['rqFee'],
      rqNonce: json['rqNonce'],
      tokenSymbol: json['tokenSymbol'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'fromAccountIndex': fromAccountIndex,
        'toAccountIndex': toAccountIndex,
        'toEthereumAddress': toEthereumAddress,
        'toBjj': toBjj,
        'tokenId': tokenId,
        'amount': amount,
        'fee': fee,
        'nonce': nonce,
        'state': state,
        'signature': signature,
        'timestamp': timestamp,
        'batchNum': batchNum,
        'rqFromAccountIndex': rqFromAccountIndex,
        'rqToAccountIndex': rqToAccountIndex,
        'rqToEthereumAddress': rqToEthereumAddress,
        'rqToBJJ': rqToBJJ,
        'rqTokenId': rqTokenId,
        'rqAmount': rqAmount,
        'rqFee': rqFee,
        'rqNonce': rqNonce,
        'tokenSymbol': tokenSymbol,
      };
}
