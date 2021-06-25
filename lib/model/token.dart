class Token {
  // ignore: non_constant_identifier_names
  final double? USD;
  final int? decimals;
  String? ethereumAddress;
  final int? ethereumBlockNum;
  final String? fiatUpdate;
  final int id;
  final int? itemId;
  final String? name;
  final String? symbol;

  Token({
    // ignore: non_constant_identifier_names
    this.USD,
    this.decimals,
    this.ethereumAddress,
    this.ethereumBlockNum,
    this.fiatUpdate,
    this.id = 0,
    this.itemId,
    this.name,
    this.symbol,
  });

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Token]
  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
        USD: json['USD'] != null ? json['USD'].toDouble() : 1.0,
        decimals: json['decimals'],
        ethereumAddress: json['ethereumAddress'],
        ethereumBlockNum: json['ethereumBlockNum'],
        fiatUpdate: json['fiatUpdate'],
        id: json['id'],
        itemId: json['itemId'],
        name: json['name'],
        symbol: json['symbol']);
  }

  Map<String, dynamic> toJson() => {
        'USD': USD,
        'decimals': decimals,
        'ethereumAddress': ethereumAddress,
        'ethereumBlockNum': ethereumBlockNum,
        'fiatUpdate': fiatUpdate,
        'id': id,
        'itemId': itemId,
        'name': name,
        'symbol': symbol,
      };
}
