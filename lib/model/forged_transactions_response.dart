import 'forged_transaction.dart';
import 'pagination.dart';

class ForgedTransactionsResponse {
  final List<ForgedTransaction> transactions;
  final Pagination pagination;

  ForgedTransactionsResponse({this.transactions, this.pagination});

  factory ForgedTransactionsResponse.fromJson(Map<String, dynamic> json) {
    List<ForgedTransaction> transactions = (json['transactions'] as List)
        ?.map((item) => ForgedTransaction.fromJson(item))
        ?.toList();
    return ForgedTransactionsResponse(
        transactions: transactions, pagination: json['pagination']);
  }

  Map<String, dynamic> toJson() => {
        'transactions': transactions,
        'pagination': pagination,
      };
}
