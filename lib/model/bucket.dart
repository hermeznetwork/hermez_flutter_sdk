class Bucket {
  final String ceilUSD;
  final String blockStamp;
  final String withdrawals;
  final String rateBlocks;
  final String rateWithdrawals;
  final String maxWithdrawals;

  Bucket(
      {this.ceilUSD,
      this.blockStamp,
      this.withdrawals,
      this.rateBlocks,
      this.rateWithdrawals,
      this.maxWithdrawals});

  factory Bucket.fromJson(Map<String, dynamic> json) {
    return Bucket(
      ceilUSD: json['ceilUSD'],
      blockStamp: json['blockStamp'],
      withdrawals: json['withdrawals'],
      rateBlocks: json['rateBlocks'],
      rateWithdrawals: json['rateWithdrawals'],
      maxWithdrawals: json['maxWithdrawals'],
    );
  }

  Map<String, dynamic> toJson() => {
        'ceilUSD': ceilUSD,
        'blockStamp': blockStamp,
        'withdrawals': withdrawals,
        'rateBlocks': rateBlocks,
        'rateWithdrawals': rateWithdrawals,
        'maxWithdrawals': maxWithdrawals,
      };
}
