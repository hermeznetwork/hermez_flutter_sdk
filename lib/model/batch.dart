class Batch {
  final int? itemId;
  final int? batchNum;
  final String? ethereumTxHash;
  final int? ethereumBlockNum;
  final String? ethereumBlockHash;
  final String? timestamp;
  final String? forgerAddr;
  final dynamic collectedFees;
  final double? historicTotalCollectedFeesUSD;
  final String? stateRoot;
  final int? numAccounts;
  final String? exitRoot;
  final int? forgeL1TransactionsNum;
  final int? slotNum;
  final int? forgedTransactions;

  Batch(
      {this.itemId,
      this.batchNum,
      this.ethereumTxHash,
      this.ethereumBlockNum,
      this.ethereumBlockHash,
      this.timestamp,
      this.forgerAddr,
      this.collectedFees,
      this.historicTotalCollectedFeesUSD,
      this.stateRoot,
      this.numAccounts,
      this.exitRoot,
      this.forgeL1TransactionsNum,
      this.slotNum,
      this.forgedTransactions});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Batch]
  factory Batch.fromJson(Map<String, dynamic> json) {
    if (json != null) {
      return Batch(
        itemId: json['itemId'],
        batchNum: json['batchNum'],
        ethereumTxHash: json['ethereumTxHash'],
        ethereumBlockNum: json['ethereumBlockNum'],
        ethereumBlockHash: json['ethereumBlockHash'],
        timestamp: json['timestamp'],
        forgerAddr: json['forgerAddr'],
        collectedFees: json['collectedFees'],
        historicTotalCollectedFeesUSD:
        json['historicTotalCollectedFeesUSD'].toDouble(),
        stateRoot: json['stateRoot'],
        numAccounts: json['numAccounts'],
        exitRoot: json['exitRoot'],
        forgeL1TransactionsNum: json['forgeL1TransactionsNum'],
        slotNum: json['slotNum'],
        forgedTransactions: json['forgedTransactions'],
      );
    } else {
      return Batch();
    }
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'batchNum': batchNum,
        'ethereumTxHash': ethereumTxHash,
        'ethereumBlockNum': ethereumBlockNum,
        'ethereumBlockHash': ethereumBlockHash,
        'timestamp': timestamp,
        'forgerAddr': forgerAddr,
        'collectedFees': collectedFees,
        'historicTotalCollectedFeesUSD': historicTotalCollectedFeesUSD,
        'stateRoot': stateRoot,
        'numAccounts': numAccounts,
        'exitRoot': exitRoot,
        'forgeL1TransactionsNum': forgeL1TransactionsNum,
        'slotNum': slotNum,
        'forgedTransactions': forgedTransactions
      };
}
