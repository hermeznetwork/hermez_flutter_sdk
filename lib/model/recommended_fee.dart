class RecommendedFee {
  final double existingAccount;
  final double createAccount;
  final double createAccountInternal;

  RecommendedFee(
      {this.existingAccount, this.createAccount, this.createAccountInternal});

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
