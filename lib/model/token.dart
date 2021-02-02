class Token {
  final double USD;
  final int decimals;
  final String ethereumAddress;
  final int ethereumBlockNum;
  final String fiatUpdate;
  final int id;
  final int itemId;
  final String name;
  final String symbol;

  Token({
    this.USD,
    this.decimals,
    this.ethereumAddress,
    this.ethereumBlockNum,
    this.fiatUpdate,
    this.id,
    this.itemId,
    this.name,
    this.symbol,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
        USD: json['USD'].toDouble(),
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
