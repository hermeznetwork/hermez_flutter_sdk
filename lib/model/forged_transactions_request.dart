class ForgedTransactionsRequest {
  final List<int>? tokenIds;
  final String? ethereumAddress;
  final String? accountIndex;
  final int? batchNum;
  final int? fromItem;

  ForgedTransactionsRequest(
      {this.tokenIds,
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
      tokenIds: json['tokenIds'],
      ethereumAddress: json['ethereumAddress'],
      accountIndex: json['accountIndex'],
      batchNum: json['batchNum'],
      fromItem: json['fromItem'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenIds': tokenIds,
        'ethereumAddress': ethereumAddress,
        'accountIndex': accountIndex,
        'batchNum': batchNum,
        'fromItem': fromItem,
      };
}
