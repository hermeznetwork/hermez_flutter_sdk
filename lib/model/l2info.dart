class L2Info {
  final int toForgeL1TransactionsNum;
  final bool userOrigin;
  final String fromEthererumAddress;
  final String fromBJJ;
  final String loadAmount;
  final int ethereumBlockNum;

  L2Info({this.toForgeL1TransactionsNum, this.userOrigin, this.fromEthererumAddress,
    this.fromBJJ, this.loadAmount, this.ethereumBlockNum});

  factory L2Info.fromJson(Map<String, dynamic> json) {
    return L2Info(
      toForgeL1TransactionsNum: json['toForgeL1TransactionsNum'],
      userOrigin: json['userOrigin'],
      fromEthererumAddress: json['fromEthererumAddress'],
      fromBJJ: json['fromBJJ'],
      loadAmount: json['loadAmount'],
      ethereumBlockNum: json['ethereumBlockNum'],
    );
  }

  Map<String, dynamic> toJson() => {
    'toForgeL1TransactionsNum': toForgeL1TransactionsNum,
    'userOrigin': userOrigin,
    'fromEthererumAddress': fromEthererumAddress,
    'fromBJJ': fromBJJ,
    'loadAmount': loadAmount,
    'ethereumBlockNum': ethereumBlockNum,
  };

}
