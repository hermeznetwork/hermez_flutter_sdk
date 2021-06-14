class MerkleProof {
  final String? root;
  final List<BigInt>? siblings;
  final String? oldKey;
  final String? oldValue;
  final bool? isOld0;
  final String? key;
  final String? value;
  final int? fnc;

  MerkleProof(
      {this.root,
      this.siblings,
      this.oldKey,
      this.oldValue,
      this.isOld0,
      this.key,
      this.value,
      this.fnc});

  factory MerkleProof.fromJson(Map<String, dynamic> json) {
    List<BigInt>? siblings = (json['siblings'] as List?)
        ?.map((item) => BigInt.parse(item))
        ?.toList();
    return MerkleProof(
        root: json['root'],
        siblings: siblings,
        oldKey: json['oldKey'],
        oldValue: json['oldValue'],
        isOld0: json['isOld0'],
        key: json['key'],
        value: json['value'],
        fnc: json['fnc']);
  }

  Map<String, dynamic> toJson() => {
        'root': root,
        'siblings': siblings,
        'oldKey': oldKey,
        'oldValue': oldValue,
        'isOld0': isOld0,
        'key': key,
        'value': value,
        'fnc': fnc
      };
}
