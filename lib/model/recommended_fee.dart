class RecommendedFee {
  final double? existingAccount;
  final double? createAccount;
  final double? createAccountInternal;

  RecommendedFee(
      {this.existingAccount, this.createAccount, this.createAccountInternal});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [RecommendedFee]
  factory RecommendedFee.fromJson(Map<String, dynamic> json) {
    return RecommendedFee(
        existingAccount: json['existingAccount'],
        createAccount: json['createAccount'],
        createAccountInternal: json['createAccountInternal']);
  }

  Map<String, dynamic> toJson() => {
        'existingAccount': existingAccount,
        'createAccount': createAccount,
        'createAccountInternal': createAccountInternal
      };
}
