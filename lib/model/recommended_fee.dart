class RecommendedFee {
  final num? existingAccount;
  final num? createAccount;
  final num? createAccountInternal;

  RecommendedFee(
      {this.existingAccount, this.createAccount, this.createAccountInternal});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [RecommendedFee]
  factory RecommendedFee.fromJson(Map<String, dynamic> json) {
    return RecommendedFee(
        existingAccount: json['existingAccount'] as num?,
        createAccount: json['createAccount'] as num?,
        createAccountInternal: json['createAccountInternal'] as num?);
  }

  Map<String, dynamic> toJson() => {
        'existingAccount': existingAccount,
        'createAccount': createAccount,
        'createAccountInternal': createAccountInternal
      };
}
