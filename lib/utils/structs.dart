import 'dart:ffi';

import 'package:ffi/ffi.dart';

class Signature extends Struct {
  // ignore: non_constant_identifier_names
  Pointer<Point>? r_b8;

  Pointer<Uint8>? s;

  factory Signature.allocate(Pointer<Point>? rB8, Pointer<Uint8>? s) =>
      calloc<Signature>().ref
        ..r_b8 = rB8
        ..s = s;
}

class Point extends Struct {
  Pointer<Uint8>? x;

  Pointer<Uint8>? y;

  Pointer<Point>? address;

  factory Point.allocate(Pointer<Uint8>? x, Pointer<Uint8>? y) {
    final pointer = calloc<Point>();
    return pointer.ref
      ..address = pointer
      ..x = x
      ..y = y;
  }
}
