import 'dart:math';

const HERMEZ_COMPRESSED_AMOUNT_TYPE = 'HermezCompressedAmount';

/// Class representing valid amounts in the Hermez network
class HermezCompressedAmount {
  String type;
  int value;

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
  /*static BigInt decompressAmount(HermezCompressedAmount hermezCompressedAmount) {
    if (!HermezCompressedAmount.isHermezCompressedAmount(hermezCompressedAmount)) {
      throw new ArgumentError('The parameter needs to be an instance of HermezCompressedAmount created with HermezCompressedAmount.compressAmount')
    }
    final fl = hermezCompressedAmount.value;
    final m = (fl & 0x3FF);
    final e = (fl >> 11);
    final e5 = (fl >> 10) & 1;

    var exp = Scalar.e(1);
    for (int i = 0; i < e; i++) {
      exp *= Scalar.e(10);
    }

    var res = Scalar.mul(m, exp);
    if (e5 && e) {
      res = Scalar.add(res, Scalar.div(exp, 2));
    }
    return res;
  }*/

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
  /*static compressAmount (_f) {
    final f = Scalar.e(_f);

    function dist (n1, n2) {
      const tmp = Scalar.sub(n1, n2)

      return Scalar.abs(tmp)
    }

    final fl1 = HermezCompressedAmount._floorCompressAmount(f);
    final fi1 = HermezCompressedAmount.decompressAmount(new HermezCompressedAmount(fl1));
    final fl2 = fl1 | 0x400;
    final fi2 = HermezCompressedAmount.decompressAmount(new HermezCompressedAmount(fl2));

    var m3 = (fl1 & 0x3FF) + 1;
    var e3 = (fl1 >> 11);
    if (m3 == 0x400) {
      m3 = 0x66; // 0x400 / 10
      e3++;
    }
    const fl3 = m3 + (e3 << 11)
    final fi3 = HermezCompressedAmount.decompressAmount(new HermezCompressedAmount(fl3));

    let res = fl1
    let d = dist(fi1, f)

    const d2 = dist(fi2, f)
    if (Scalar.gt(d, d2)) {
      res = fl2
      d = d2
    }

    const d3 = dist(fi3, f)
    if (Scalar.gt(d, d3)) {
      res = fl3
    }

    return new HermezCompressedAmount(res);
  }*/

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
