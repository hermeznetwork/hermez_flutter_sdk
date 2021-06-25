class ForgedTransactionsRequest {
  final int? tokenId;
  final String? ethereumAddress;
  final String? accountIndex;
  final int? batchNum;
  final int? fromItem;

  ForgedTransactionsRequest(
      {this.tokenId,
      this.ethereumAddress,
      this.accountIndex,
      this.batchNum,
      this.fromItem});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [ForgedTransactionsRequest]
  factory ForgedTransactionsRequest.fromJson(Map<String, dynamic> json) {
    return ForgedTransactionsRequest(
      tokenId: json['tokenId'],
      ethereumAddress: json['ethereumAddress'],
      accountIndex: json['accountIndex'],
      batchNum: json['batchNum'],
      fromItem: json['fromItem'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'ethereumAddress': ethereumAddress,
        'accountIndex': accountIndex,
        'batchNum': batchNum,
        'fromItem': fromItem,
      };
}
