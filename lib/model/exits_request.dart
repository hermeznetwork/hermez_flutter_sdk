class ExitsRequest {
  final String hezEthereumAddress;
  final bool onlyPendingWithdraws;

  ExitsRequest({this.hezEthereumAddress, this.onlyPendingWithdraws});

  factory ExitsRequest.fromJson(Map<String, dynamic> json) {
    return ExitsRequest(
      hezEthereumAddress: json['hezEthereumAddress'],
      onlyPendingWithdraws: json['onlyPendingWithdraws'],
    );
  }

  Map<String, dynamic> toJson() => {
        'hezEthereumAddress': hezEthereumAddress,
        'onlyPendingWithdraws': onlyPendingWithdraws,
      };
}
