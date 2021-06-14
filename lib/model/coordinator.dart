class Coordinator {
  final int? itemId;
  final String? forgerAddr;
  final String? bidderAddr;
  final String? URL;
  final int? ethereumBlock;

  Coordinator(
      {this.itemId,
      this.forgerAddr,
      this.bidderAddr,
      this.URL,
      this.ethereumBlock});

  factory Coordinator.fromJson(Map<String, dynamic> json) {
    return Coordinator(
        itemId: json['itemId'],
        forgerAddr: json['forgerAddr'],
        bidderAddr: json['bidderAddr'],
        URL: json['URL'],
        ethereumBlock: json['ethereumBlock']);
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'forgerAddr': forgerAddr,
        'bidderAddr': bidderAddr,
        'URL': URL,
        'ethereumBlock': ethereumBlock
      };
}
