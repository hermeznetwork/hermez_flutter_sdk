class L2Info {
  final int fee;
  final double historicFeeUSD;
  final int nonce;

  L2Info({this.fee, this.historicFeeUSD, this.nonce});

  factory L2Info.fromJson(Map<String, dynamic> json) {
    if (json != null) {
      return L2Info(
        fee: json['fee'],
        historicFeeUSD: double.tryParse(json['historicFeeUSD'].toString()) ?? 0.0,
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
