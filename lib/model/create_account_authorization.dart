class CreateAccountAuthorization {
  final String? hezEthereumAddress;
  final String? bjj;
  final String? signature;
  final String? timestamp;

  CreateAccountAuthorization(
      {this.hezEthereumAddress, this.bjj, this.signature, this.timestamp});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [CreateAccountAuthorization]
  factory CreateAccountAuthorization.fromJson(Map<String, dynamic> json) {
    return CreateAccountAuthorization(
        hezEthereumAddress: json['hezEthereumAddress'],
        bjj: json['bjj'],
        signature: json['signature'],
        timestamp: json['timestamp']);
  }

  Map<String, dynamic> toJson() => {
        'hezEthereumAddress': hezEthereumAddress,
        'bjj': bjj,
        'signature': signature,
        'timestamp': timestamp
      };
}
