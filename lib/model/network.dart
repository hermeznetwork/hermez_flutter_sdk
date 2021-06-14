import 'batch.dart';
import 'forger.dart';

class Network {
  final int? lastEthereumBlock;
  final int? lastSynchedBlock;
  final Batch? lastBatch;
  final int? currentSlot;
  final List<Forger>? nextForgers;

  Network(
      {this.lastEthereumBlock,
      this.lastSynchedBlock,
      this.lastBatch,
      this.currentSlot,
      this.nextForgers});

  factory Network.fromJson(Map<String, dynamic> json) {
    Batch lastBatch = Batch.fromJson(json['lastBatch']);
    var forgersFromJson = json['nextForgers'] as List;
    List<Forger> forgersList =
        forgersFromJson.map((i) => Forger.fromJson(i)).toList();
    return Network(
      lastEthereumBlock: json['lastEthereumBlock'],
      lastSynchedBlock: json['lastSynchedBlock'],
      lastBatch: lastBatch,
      currentSlot: json['currentSlot'],
      nextForgers: forgersList,
    );
  }

  Map<String, dynamic> toJson() => {
        'lastEthereumBlock': lastEthereumBlock,
        'lastSynchedBlock': lastSynchedBlock,
        'lastBatch': lastBatch!.toJson(),
        'currentSlot': currentSlot,
        'nextForgers': nextForgers,
      };
}
