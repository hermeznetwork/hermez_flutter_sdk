class Batch {
  final int itemId;
  final int batchNum;
  final int ethereumBlockNum;
  final String ethereumBlockHash;
  final String timestamp;
  final String forgerAddr;
  final dynamic collectedFees;
  final int historicTotalCollectedFeesUSD;
  final String stateRoot;
  final int numAccounts;
  final String exitRoot;
  final int forgeL1TransactionsNum;
  final int slotNum;
  final int forgedTransactions;

  Batch(
      {this.itemId,
      this.batchNum,
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

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      itemId: json['itemId'],
      batchNum: json['batchNum'],
      ethereumBlockNum: json['ethereumBlockNum'],
      ethereumBlockHash: json['ethereumBlockHash'],
      timestamp: json['timestamp'],
      forgerAddr: json['forgerAddr'],
      collectedFees: json['collectedFees'],
      historicTotalCollectedFeesUSD: json['historicTotalCollectedFeesUSD'],
      stateRoot: json['stateRoot'],
      numAccounts: json['numAccounts'],
      exitRoot: json['exitRoot'],
      forgeL1TransactionsNum: json['forgeL1TransactionsNum'],
      slotNum: json['slotNum'],
      forgedTransactions: json['forgedTransactions'],
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'batchNum': batchNum,
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
