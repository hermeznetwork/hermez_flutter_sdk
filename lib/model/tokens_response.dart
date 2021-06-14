import 'package:hermez_sdk/model/token.dart';

class TokensResponse {
  final List<Token>? tokens;
  final int? pendingItems;

  TokensResponse({this.tokens, this.pendingItems});

  factory TokensResponse.fromJson(Map<String, dynamic> parsedJson) {
    var tokensFromJson = parsedJson['tokens'] as List;
    List<Token> tokensList =
        tokensFromJson.map((i) => Token.fromJson(i)).toList();
    final pendingItems = parsedJson['pendingItems'] as int?;
    return TokensResponse(tokens: tokensList, pendingItems: pendingItems);
  }

  Map<String, dynamic> toJson() =>
      {'tokens': tokens, 'pendingItems': pendingItems};
}
