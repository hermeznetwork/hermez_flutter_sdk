import 'coordinator.dart';

class CoordinatorsResponse {
  final List<Coordinator> coordinators;
  final int pendingItems;

  CoordinatorsResponse({this.coordinators, this.pendingItems});

  factory CoordinatorsResponse.fromJson(Map<String, dynamic> json) {
    return CoordinatorsResponse(
        coordinators: json['coordinators'], pendingItems: json['pendingItems']);
  }

  Map<String, dynamic> toJson() => {
        'coordinators': coordinators,
        'pendingItems': pendingItems,
      };
}
