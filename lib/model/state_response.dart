import 'dart:collection';

import 'metrics.dart';
import 'network.dart';
import 'recommended_fee.dart';
import 'rollup.dart';
import 'withdrawal_delayer.dart';

class StateResponse {
  final Network? network;
  final Metrics? metrics;
  final Rollup? rollup;
  final LinkedHashMap<String, dynamic>? auction;
  final WithdrawalDelayer? withdrawalDelayer;
  final RecommendedFee? recommendedFee;

  StateResponse(
      {this.network,
      this.metrics,
      this.rollup,
      this.auction,
      this.withdrawalDelayer,
      this.recommendedFee});

  /// Creates an instance from the given json
  ///
  /// @param [Map<String, dynamic>] json
  /// @returns [StateResponse]
  factory StateResponse.fromJson(Map<String, dynamic> json) {
    Network network = Network.fromJson(json['network']);
    Metrics metrics = Metrics.fromJson(json['metrics']);
    Rollup rollup = Rollup.fromJson(json['rollup']);
    WithdrawalDelayer withdrawalDelayer =
        WithdrawalDelayer.fromJson(json['withdrawalDelayer']);
    RecommendedFee recommendedFee =
        RecommendedFee.fromJson(json['recommendedFee']);
    return StateResponse(
        network: network,
        metrics: metrics,
        rollup: rollup,
        auction: json['auction'],
        withdrawalDelayer: withdrawalDelayer,
        recommendedFee: recommendedFee);
  }

  Map<String, dynamic> toJson() => {
        'network': network!.toJson(),
        'metrics': metrics,
        'rollup': rollup,
        'auction': auction,
        'withdrawalDelayer': withdrawalDelayer!.toJson(),
        'recommendedFee': recommendedFee!.toJson(),
      };
}
