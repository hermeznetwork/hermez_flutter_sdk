import 'dart:collection';

import 'network.dart';
import 'recommended_fee.dart';

class StateResponse {
  final Network network;
  final LinkedHashMap<String, dynamic> metrics;
  final LinkedHashMap<String, dynamic> rollup;
  final LinkedHashMap<String, dynamic> auction;
  final LinkedHashMap<String, dynamic> withdrawalDelayer;
  final RecommendedFee recommendedFee;

  StateResponse(
      {this.network,
      this.metrics,
      this.rollup,
      this.auction,
      this.withdrawalDelayer,
      this.recommendedFee});

  factory StateResponse.fromJson(Map<String, dynamic> json) {
    Network network = Network.fromJson(json['network']);
    RecommendedFee recommendedFee =
        RecommendedFee.fromJson(json['recommendedFee']);
    return StateResponse(
        network: network,
        metrics: json['metrics'],
        rollup: json['rollup'],
        auction: json['auction'],
        withdrawalDelayer: json['withdrawalDelayer'],
        recommendedFee: recommendedFee);
  }

  Map<String, dynamic> toJson() => {
        'network': network.toJson(),
        'metrics': metrics,
        'rollup': rollup,
        'auction': auction,
        'withdrawalDelayer': withdrawalDelayer,
        'recommendedFee': recommendedFee.toJson(),
      };
}
