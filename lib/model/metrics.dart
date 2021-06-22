class Metrics {
  final num? transactionsPerBatch;
  final num? batchFrequency;
  final num? transactionsPerSecond;
  final int? tokenAccounts;
  final int? wallets;
  final num? avgTransactionFee;
  final num? estimatedTimeToForgeL1;

  Metrics(
      {this.transactionsPerBatch,
      this.batchFrequency,
      this.transactionsPerSecond,
      this.tokenAccounts,
      this.wallets,
      this.avgTransactionFee,
      this.estimatedTimeToForgeL1});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Metrics]
  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
        transactionsPerBatch: json['transactionsPerBatch'] as num?,
        batchFrequency: json['batchFrequency'] as num?,
        transactionsPerSecond: json['transactionsPerSecond'] as num?,
        tokenAccounts: json['tokenAccounts'],
        wallets: json['wallets'],
        avgTransactionFee: json['avgTransactionFee'] as num?,
        estimatedTimeToForgeL1: json['estimatedTimeToForgeL1'] as num?);
  }

  Map<String, dynamic> toJson() => {
        'transactionsPerBatch': transactionsPerBatch,
        'batchFrequency': batchFrequency,
        'transactionsPerSecond': transactionsPerSecond,
        'wallets': wallets,
        'avgTransactionFee': avgTransactionFee,
        'estimatedTimeToForgeL1': estimatedTimeToForgeL1,
      };
}
