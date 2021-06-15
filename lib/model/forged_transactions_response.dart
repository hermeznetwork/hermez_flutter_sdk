import 'forged_transaction.dart';

class ForgedTransactionsResponse {
  final List<ForgedTransaction>? transactions;
  final int? pendingItems;

  ForgedTransactionsResponse({this.transactions, this.pendingItems});

  factory ForgedTransactionsResponse.fromJson(Map<String, dynamic> json) {
    List<ForgedTransaction>? transactions = (json['transactions'] as List?)
        ?.map((item) => ForgedTransaction.fromJson(item))
        .toList();
    return ForgedTransactionsResponse(
        transactions: transactions, pendingItems: json['pendingItems']);
  }

  Map<String, dynamic> toJson() => {
        'transactions': transactions,
        'pendingItems': pendingItems,
      };
}
