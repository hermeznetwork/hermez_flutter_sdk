class Pagination {
  final int? totalItems;
  final int? lastReturnedItem;

  Pagination({this.totalItems, this.lastReturnedItem});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
        totalItems: json['totalItems'],
        lastReturnedItem: json['lastReturnedItem']);
  }

  Map<String, dynamic> toJson() => {
        'totalItems': totalItems,
        'lastReturnedItem': lastReturnedItem,
      };
}
