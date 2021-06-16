class L1Info {
  final bool? amountSuccess;
  final String? depositAmount;
  final bool? depositAmountSuccess;
  final int? ethereumBlockNum;
  final double? historicDepositAmountUSD;
  final int? toForgeL1TransactionsNum;
  final bool? userOrigin;

  L1Info(
      {this.amountSuccess,
      this.depositAmount,
      this.depositAmountSuccess,
      this.ethereumBlockNum,
      this.historicDepositAmountUSD,
      this.toForgeL1TransactionsNum,
      this.userOrigin});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [L1Info]
  factory L1Info.fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return L1Info(
        amountSuccess: json['amountSuccess'],
        depositAmount: json['depositAmount'],
        depositAmountSuccess: json['depositAmountSuccess'],
        ethereumBlockNum: json['ethereumBlockNum'],
        historicDepositAmountUSD:
            double.tryParse(json['historicDepositAmountUSD'].toString()) ?? 0.0,
        toForgeL1TransactionsNum: json['toForgeL1TransactionsNum'],
        userOrigin: json['userOrigin'],
      );
    } else {
      return L1Info();
    }
  }

  Map<String, dynamic> toJson() => {
        'amountSuccess': amountSuccess,
        'depositAmount': depositAmount,
        'depositAmountSuccess': depositAmountSuccess,
        'ethereumBlockNum': ethereumBlockNum,
        'historicDepositAmountUSD': historicDepositAmountUSD,
        'toForgeL1TransactionsNum': toForgeL1TransactionsNum,
        'userOrigin': userOrigin,
      };
}
