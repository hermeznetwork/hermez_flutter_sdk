class L2Info {
  final int fee;
  final double historicFeeUSD;
  final int nonce;

  L2Info({this.fee, this.historicFeeUSD, this.nonce});

  factory L2Info.fromJson(Map<String, dynamic> json) {
    if (json != null) {
      return L2Info(
        fee: json['fee'],
        historicFeeUSD: json['historicFeeUSD'],
        nonce: json['nonce'],
      );
    } else {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'fee': fee,
        'historicFeeUSD': historicFeeUSD,
        'nonce': nonce,
      };
}
