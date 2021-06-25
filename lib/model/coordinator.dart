class Coordinator {
  final int? itemId;
  final String? forgerAddr;
  final String? bidderAddr;
  // ignore: non_constant_identifier_names
  final String? URL;
  final int? ethereumBlock;

  Coordinator(
      {this.itemId,
      this.forgerAddr,
      this.bidderAddr,
      // ignore: non_constant_identifier_names
      this.URL,
      this.ethereumBlock});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Coordinator]
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
