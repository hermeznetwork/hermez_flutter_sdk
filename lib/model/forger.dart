import 'coordinator.dart';
import 'period.dart';

class Forger {
  final Coordinator coordinator;
  final Period period;

  Forger({this.coordinator, this.period});

  factory Forger.fromJson(Map<String, dynamic> json) {
    Coordinator coordinator = Coordinator.fromJson(json['coordinator']);
    Period period = Period.fromJson(json['period']);
    return Forger(
      coordinator: coordinator,
      period: period,
    );
  }

  Map<String, dynamic> toJson() => {
        'coordinator': coordinator.toJson(),
        'period': period.toJson(),
      };
}
