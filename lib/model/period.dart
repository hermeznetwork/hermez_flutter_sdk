class Period {
  final int? slotNum;
  final int? fromBlock;
  final int? toBlock;
  final String? fromTimestamp;
  final String? toTimestamp;

  Period(
      {this.slotNum,
      this.fromBlock,
      this.toBlock,
      this.fromTimestamp,
      this.toTimestamp});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Period]
  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
        slotNum: json['slotNum'],
        fromBlock: json['fromBlock'],
        toBlock: json['toBlock'],
        fromTimestamp: json['fromTimestamp'],
        toTimestamp: json['toTimestamp']);
  }

  Map<String, dynamic> toJson() => {
        'slotNum': slotNum,
        'fromBlock': fromBlock,
        'toBlock': toBlock,
        'fromTimestamp': fromTimestamp,
        'toTimestamp': toTimestamp,
      };
}
