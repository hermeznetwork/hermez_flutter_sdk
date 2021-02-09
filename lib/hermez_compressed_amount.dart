const HERMEZ_COMPRESSED_AMOUNT_TYPE = 'HermezCompressedAmount';

/// Class representing valid amounts in the Hermez network
class HermezCompressedAmount {
  String type;
  BigInt value;

  /// Builds an instance of HermezCompressedAmount, a wrapper
  /// for compressed BigInts in 40 bits used within the Hermez network
  /// @param {num} value - Compressed representation of a BigInt in a 40bit Number
  HermezCompressedAmount(BigInt value) {
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
  /* static BigInt decompressAmount(HermezCompressedAmount hermezCompressedAmount) {
    if (!HermezCompressedAmount.isHermezCompressedAmount(hermezCompressedAmount)) {
      throw new ArgumentError('The parameter needs to be an instance of HermezCompressedAmount created with HermezCompressedAmount.compressAmount')
    }
    final fl = hermezCompressedAmount.value;
    final m = (fl & 0x3FF);
    final e = (fl >> 11);
    final e5 = (fl >> 10) & 1;

    var exp = Scalar.e(1)
    for (int i = 0; i < e; i++) {
      exp *= Scalar.e(10);
    }

    let res = Scalar.mul(m, exp);
    if (e5 && e) {
      res = Scalar.add(res, Scalar.div(exp, 2));
    }
    return res;
  }

  /// Convert a fix to a float, always rounding down
  /// @param {String} _f - Scalar encoded in fix
  /// @returns {Scalar} Scalar encoded in float
  /// @private
  static BigInt _floorCompressAmount (_f) {
    final f = Scalar.e(_f);
    if (Scalar.isZero(f)) return 0;

    var m = f;
    var e = 0;

    while (!Scalar.isZero(Scalar.shr(m, 10))) {
      m = Scalar.div(m, 10);
      e++;
    }

    final res = Scalar.toNumber(m) + (e << 11);
    return res;
  }

  /// Convert a fix to a float
  /// @param {String} _f - Scalar encoded in fix
  /// @returns {HermezCompressedAmount} HermezCompressedAmount representation of the amount
  static compressAmount (_f) {
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
  }

  /// Convert a float to a fix, always rounding down
  /// @param {Scalar} fl - Scalar encoded in fix
  /// @returns {HermezCompressedAmount} HermezCompressedAmount representation of the amount
  static floorCompressAmount (_f) {
    final f = Scalar.e(_f);

    final fl1 = HermezCompressedAmount._floorCompressAmount(f);
    final fl2 = fl1 | 0x400;
    final fi2 = HermezCompressedAmount.decompressAmount(new HermezCompressedAmount(fl2));

    if (Scalar.leq(fi2, f)) {
      return new HermezCompressedAmount(fl2);
    } else {
      return new HermezCompressedAmount(fl1);
    }
  }*/
}
