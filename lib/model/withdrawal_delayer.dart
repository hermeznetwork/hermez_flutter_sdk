class WithdrawalDelayer {
  final int? ethereumBlockNum;
  final String? ethereumGovernanceAddress;
  final String? emergencyCouncilAddress;
  // The time that everyone needs to wait until a withdrawal of the funds is allowed, in seconds.
  final int? withdrawalDelay;
  final int? emergencyModeStartingBlock;
  final bool? emergencyMode;

  WithdrawalDelayer(
      {this.ethereumBlockNum,
      this.ethereumGovernanceAddress,
      this.emergencyCouncilAddress,
      this.withdrawalDelay,
      this.emergencyModeStartingBlock,
      this.emergencyMode});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [WithdrawalDelayer]
  factory WithdrawalDelayer.fromJson(Map<String, dynamic> json) {
    return WithdrawalDelayer(
      ethereumBlockNum: json['ethereumBlockNum'],
      ethereumGovernanceAddress: json['ethereumGovernanceAddress'],
      emergencyCouncilAddress: json['emergencyCouncilAddress'],
      withdrawalDelay: json['withdrawalDelay'],
      emergencyModeStartingBlock: json['emergencyModeStartingBlock'],
      emergencyMode: json['emergencyMode'],
    );
  }

  Map<String, dynamic> toJson() => {
        'ethereumBlockNum': ethereumBlockNum,
        'ethereumGovernanceAddress': ethereumGovernanceAddress,
        'emergencyCouncilAddress': emergencyCouncilAddress,
        'withdrawalDelay': withdrawalDelay,
        'emergencyModeStartingBlock': emergencyModeStartingBlock,
        'emergencyMode': emergencyMode
      };
}
