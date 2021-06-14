class TokensRequest {
  final List<int>? ids;
  final List<String>? symbols;
  final List<String>? name;
  final int? offset;
  final int? limit;

  TokensRequest({this.ids, this.symbols, this.name, this.offset, this.limit});

  factory TokensRequest.fromJson(Map<String, dynamic> json) {
    return TokensRequest(
        ids: json['ids'],
        symbols: json['symbols'],
        name: json['name'],
        offset: json['offset'],
        limit: json['limit']);
  }

  Map<String, String> toJson() => {
        'ids': ids.toString(),
        'symbols': symbols.toString(),
        'name': name.toString(),
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
}
