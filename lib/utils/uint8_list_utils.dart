import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

class Uint8ArrayUtils {
  static Uint8List fromPointer(Pointer<Uint8> ptr, int length) {
    final view = ptr.asTypedList(length);
    final builder = BytesBuilder(copy: false);
    builder.add(view);
    return builder.takeBytes();
  }

  static Pointer<Uint8> toPointer(Uint8List bytes) {
    final ptr = allocate<Uint8>(count: bytes.length);
    final byteList = ptr.asTypedList(bytes.length);
    byteList.setAll(0, bytes);
    return ptr.cast();
  }

  static Uint8List uint8ListfromString(String text) {
    List<int> list = text.codeUnits;
    return Uint8List.fromList(list);
  }

  static String uint8ListToString(Uint8List bytes) {
    return String.fromCharCodes(bytes);
  }
}
