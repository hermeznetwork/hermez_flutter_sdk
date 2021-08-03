const HERMEZ_COMPRESSED_AMOUNT_TYPE = 'HermezCompressedAmount';

/// Class representing valid amounts in the Hermez network
class HermezCompressedAmount {
  String? type;
  late num value;

  /// Builds an instance of HermezCompressedAmount, a wrapper
  /// for compressed BigInts in 40 bits used within the Hermez network
  ///
  /// @param [num] value - Compressed representation of a BigInt in a 40bit Number
  HermezCompressedAmount(num value) {
    this.type = HERMEZ_COMPRESSED_AMOUNT_TYPE;
    this.value = value;
  }

  /// Checks if HermezCompressedAmount representation is an instance of HermezCompressedAmount
  ///
  /// @param [HermezCompressedAmount] instance
  /// @returns [bool] returns true if is HermezCompressedAmount
  static bool isHermezCompressedAmount(HermezCompressedAmount instance) {
    return instance.type == HERMEZ_COMPRESSED_AMOUNT_TYPE &&
        instance.runtimeType == HermezCompressedAmount;
  }

  /// Decompress a HermezCompressedAmount to a double amount
  ///
  /// @param [HermezCompressedAmount] hermezCompressedAmount - HermezCompressedAmount representation of the amount
  /// @returns [double] decompressed double amount
  static double decompressAmount(
      HermezCompressedAmount hermezCompressedAmount) {
    if (!HermezCompressedAmount.isHermezCompressedAmount(
        hermezCompressedAmount)) {
      throw new ArgumentError(
          'The parameter needs to be an instance of HermezCompressedAmount created with HermezCompressedAmount.compressAmount');
    }
    final fl = hermezCompressedAmount.value;
    final m = (fl % 0x800000000);
    final e = (fl / 0x800000000).floor();

    var exp = BigInt.from(1);
    for (var i = 0; i < e; i++) {
      exp *= BigInt.from(10);
    }

    final double res = m * exp.toDouble();

    return res;
  }

  /// Convert a double amount to a HermezCompressedAmount object
  ///
  /// @param [double] f - double amount
  /// @returns [HermezCompressedAmount] HermezCompressedAmount representation of the amount
  static HermezCompressedAmount compressAmount(double f) {
    if (f.sign == 0) {
      return new HermezCompressedAmount(0);
    }

    var m = f;
    var e = 0;

    while ((m % 10).floor().sign == 0 && (m / 0x800000000).floor().sign != 0) {
      m = m / 10;
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }

    if ((m / 0x800000000).floor().sign != 0) {
      throw new ArgumentError("not enough precision");
    }

    final res = m + (e * 0x800000000);

    return new HermezCompressedAmount(res);
  }

  /// Convert a float to a fix, always rounding down
  /// @param {Scalar} fl - Scalar encoded in fix
  /// @returns {HermezCompressedAmount} HermezCompressedAmount representation of the amount
  static HermezCompressedAmount floorCompressAmount(double f) {
    if (f.sign == 0) {
      return new HermezCompressedAmount(0);
    }

    var m = f;
    var e = 0;

    while ((m / 0x800000000).floor().sign != 0) {
      m = m / 10;
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }

    final res = m + (e * 0x800000000);

    return new HermezCompressedAmount(res);
  }
}
