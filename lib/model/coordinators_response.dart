import 'coordinator.dart';

class CoordinatorsResponse {
  final List<Coordinator>? coordinators;
  final int? pendingItems;

  CoordinatorsResponse({this.coordinators, this.pendingItems});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [CoordinatorsResponse]
  factory CoordinatorsResponse.fromJson(Map<String, dynamic> json) {
    List<Coordinator>? coordinators = (json['coordinators'] as List?)
        ?.map((item) => Coordinator.fromJson(item))
        .toList();
    return CoordinatorsResponse(
        coordinators: coordinators, pendingItems: json['pendingItems']);
  }

  Map<String, dynamic> toJson() => {
        'coordinators': coordinators,
        'pendingItems': pendingItems,
      };
}
