class WithdrawalDelayer {
  final int? ethereumBlockNum;
  final String? ethereumGovernanceAddress;
  final String? emergencyCouncilAddress;
  final int?
      withdrawalDelay; // The time that everyone needs to wait until a withdrawal of the funds is allowed, in seconds.
  final int? emergencyModeStartingBlock;
  final bool? emergencyMode;

  WithdrawalDelayer(
      {this.ethereumBlockNum,
      this.ethereumGovernanceAddress,
      this.emergencyCouncilAddress,
      this.withdrawalDelay,
      this.emergencyModeStartingBlock,
      this.emergencyMode});

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
