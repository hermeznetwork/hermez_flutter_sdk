import 'bucket.dart';

class Rollup {
  final int ethereumBlockNum;
  final int forgeL1L2BatchTimeout;
  final String feeAddToken;
  final int
      withdrawalDelay; // The time that everyone needs to wait until a withdrawal of the funds is allowed, in seconds.
  final List<Bucket> buckets;

  Rollup(
      {this.ethereumBlockNum,
      this.forgeL1L2BatchTimeout,
      this.feeAddToken,
      this.withdrawalDelay,
      this.buckets});

  factory Rollup.fromJson(Map<String, dynamic> json) {
    var bucketsFromJson = json['buckets'] as List;
    List<Bucket> bucketsList =
        bucketsFromJson.map((i) => Bucket.fromJson(i)).toList();
    return Rollup(
      ethereumBlockNum: json['ethereumBlockNum'],
      forgeL1L2BatchTimeout: json['forgeL1L2BatchTimeout'],
      feeAddToken: json['feeAddToken'],
      withdrawalDelay: json['withdrawalDelay'],
      buckets: bucketsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'ethereumBlockNum': ethereumBlockNum,
        'forgeL1L2BatchTimeout': forgeL1L2BatchTimeout,
        'feeAddToken': feeAddToken,
        'withdrawalDelay': withdrawalDelay,
        'buckets': buckets,
      };
}
