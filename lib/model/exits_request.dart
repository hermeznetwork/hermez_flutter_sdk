class ExitsRequest {
  final String? hezEthereumAddress;
  final bool? onlyPendingWithdraws;
  final int? tokenId;

  ExitsRequest(
      {this.hezEthereumAddress, this.onlyPendingWithdraws, this.tokenId});

  factory ExitsRequest.fromJson(Map<String, dynamic> json) {
    return ExitsRequest(
        hezEthereumAddress: json['hezEthereumAddress'],
        onlyPendingWithdraws: json['onlyPendingWithdraws'],
        tokenId: json['tokenId']);
  }

  Map<String, dynamic> toJson() => {
        'hezEthereumAddress': hezEthereumAddress,
        'onlyPendingWithdraws': onlyPendingWithdraws,
        'tokenId': tokenId
      };
}
