import 'dart:math';

const HERMEZ_COMPRESSED_AMOUNT_TYPE = 'HermezCompressedAmount';

/// Class representing valid amounts in the Hermez network
class HermezCompressedAmount {
  String type;
  num value;

  /// Builds an instance of HermezCompressedAmount, a wrapper
  /// for compressed BigInts in 40 bits used within the Hermez network
  /// @param {num} value - Compressed representation of a BigInt in a 40bit Number
  HermezCompressedAmount(num value) {
    this.type = HERMEZ_COMPRESSED_AMOUNT_TYPE;
    this.value = value;
  }

  ///
  /// @param {HermezCompressedAmount} instance
  static bool isHermezCompressedAmount(HermezCompressedAmount instance) {
    return instance.type == HERMEZ_COMPRESSED_AMOUNT_TYPE &&
        instance.runtimeType == HermezCompressedAmount;
  }

  /// Convert a HermezCompressedAmount to a fix
  /// @param {Scalar} fl - HermezCompressedAmount representation of the amount
  /// @returns {Scalar} Scalar encoded in fix
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

    //final exp = pow(10, e);

    final double res = m * exp.toDouble();

    return res;
  }

  /// Convert a fix to a float, always rounding down
  /// @param {double} _f - BigInt encoded in double
  /// @returns {BigInt} BigInt encoded in float
  /// @private
  /*static BigInt _floorCompressAmount(double fl) {
    final m = (fl % 0x800000000);
    final e = (fl / 0x800000000).floor();

    final exp = pow(10, e);

    final res = mul(m, exp);

    return res;
  }*/

  /// Convert a fix to a float
  /// @param {String} _f - Scalar encoded in fix
  /// @returns {HermezCompressedAmount} HermezCompressedAmount representation of the amount
  static HermezCompressedAmount compressAmount(double f) {
    //double f = double.parse(_f);
    if (f.sign == 0) {
      return new HermezCompressedAmount(0);
    }

    var m = f;
    var e = 0;

    while ((m % 10).sign == 0 && (m / 0x800000000).sign != 0) {
      m = m / 10;
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }
    var eight = BigInt.from(0x800000000);

    if ((m / 0x800000000).toInt().sign != 0) {
      throw new ArgumentError("not enough precision");
    }

    final res = m + (e * 0x800000000);

    return new HermezCompressedAmount(res);
  }

  /// Convert a float to a fix
  /// @param {Scalar} fl - Scalar encoded in float
  /// @returns {Scalar} Scalar encoded in fix
  static num float2Fix(num fl) {
    final m = (fl % 0x800000000);
    final e = (fl / 0x800000000).floor();

    final exp = pow(10, e);

    final res = m * exp;

    return res;
  }

  /// Convert a fix to a float
  /// @param {String|Number} _f - Scalar encoded in fix
  /// @returns {Scalar} Scalar encoded in float
  static BigInt fix2Float(num _f) {
    final f = BigInt.from(_f);

    if (f.sign == 0) return BigInt.zero;

    var m = f;
    var e = 0;

    while ((m % BigInt.from(10)).sign == 0 &&
        (BigInt.from(m / BigInt.from(0x800000000)).sign != 0)) {
      m = BigInt.from(m / BigInt.from(10));
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }

    if (BigInt.from(m / BigInt.from(0x800000000)).sign != 0) {
      throw new ArgumentError("not enough precision");
    }

    final res = m.toDouble() + (e * 0x800000000);
    return BigInt.from(res);
  }

  /// Convert a float to a fix, always rounding down
  /// @param {Scalar} fl - Scalar encoded in float
  /// @returns {Scalar} Scalar encoded in fix
  static BigInt floorFix2Float(num _f) {
    final f = BigInt.from(_f);

    if (f.sign == 0) return BigInt.zero;

    var m = f;
    var e = 0;

    while (BigInt.from(m / BigInt.from(0x800000000)).sign != 0) {
      m = BigInt.from(m / BigInt.from(10));
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }

    final res = m.toDouble() + (e * 0x800000000);
    return BigInt.from(res);
  }

  /// Round large integer by encode-decode in float40 encoding
  /// @param {Scalar} fix
  /// @returns {Scalar} fix rounded
  static round(num fix) {
    final f = BigInt.from(fix);

    if (f.sign == 0) return BigInt.zero;

    var m = f;
    var e = 0;

    while (BigInt.from(m / BigInt.from(0x800000000)).sign != 0) {
      final roundUp = (m % BigInt.from(10)).toInt() > 5;
      m = BigInt.from(m / BigInt.from(10));
      if (roundUp) m = m + BigInt.one;
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }

    final res = m.toDouble() + (e * 0x800000000);
    return float2Fix(res);
  }

  /// Convert a float to a fix, always rounding down
  /// @param {BigInt} fl - BigInt encoded in double
  /// @returns {BigInt} BigInt encoded in fix
  /*static BigInt floorCompressAmount(num fl) {
    final f = BigInt.from(fl);

    if (f.sign == 0) return BigInt.zero;

    var m = f;
    var e = 0;

    while (BigInt.from(m / BigInt.from(0x800000000)).sign != 0) {
      m = BigInt.from(m / BigInt.from(10));
      e++;
    }

    if (e > 31) {
      throw new ArgumentError("number too big");
    }

    final res = m.toDouble() + (e * 0x800000000);
    return BigInt.from(res);
  }*/
}
