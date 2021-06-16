class Metrics {
  final double? transactionsPerBatch;
  final double? batchFrequency;
  final double? transactionsPerSecond;
  final int? tokenAccounts;
  final int? wallets;
  final double? avgTransactionFee;
  final double? estimatedTimeToForgeL1;

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
        transactionsPerBatch: json['transactionsPerBatch'],
        batchFrequency: json['batchFrequency'],
        transactionsPerSecond: json['transactionsPerSecond'],
        tokenAccounts: json['tokenAccounts'],
        wallets: json['wallets'],
        avgTransactionFee: json['avgTransactionFee'],
        estimatedTimeToForgeL1: json['estimatedTimeToForgeL1']);
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
