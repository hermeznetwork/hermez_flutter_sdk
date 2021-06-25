class Node {
  final int? forgeDelay;
  final int? poolLoad;

  Node({this.forgeDelay, this.poolLoad});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [Node]
  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      forgeDelay: json['forgeDelay'],
      poolLoad: json['poolLoad'],
    );
  }

  Map<String, dynamic> toJson() => {
        'forgeDelay': forgeDelay,
        'poolLoad': poolLoad,
      };
}
