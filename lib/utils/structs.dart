import 'dart:ffi';

import 'package:ffi/ffi.dart';

// Example of using structs to pass strings to and from Dart/C
/*class Utf8 extends Struct {
  @ffi.Uint8()
  int char;

  static String fromUtf8(Pointer<Utf8> ptr) {
    final units = List<int>();
    var len = 0;
    while (true) {
      final char = ptr.elementAt(len++).load<Utf8>().char;
      if (char == 0) break;
      units.add(char);
    }
    return Utf8Decoder().convert(units);
  }

  static Pointer<Utf8> toUtf8(String s) {
    final units = Utf8Encoder().convert(s);
    final ptr = Pointer<Utf8>.allocate(count: units.length + 1);
    for (var i = 0; i < units.length; i++) {
      ptr.elementAt(i).load<Utf8>().char = units[i];
    }
    // Add the C string null terminator '\0'
    ptr.elementAt(units.length).load<Utf8>().char = 0;
    return ptr;
  }
}*/

// Example of handling a simple C struct
/*class Coordinate extends Struct {
  @Double()
  double latitude;

  @Double()
  double longitude;

  factory Coordinate.allocate(double latitude, double longitude) =>
      allocate<Coordinate>().ref
        ..latitude = latitude
        ..longitude = longitude;
}*/

class Signature extends Struct {
  Pointer<Point> r_b8;

  Pointer<Uint8> s;

  factory Signature.allocate(Pointer<Point> r_b8, Pointer<Uint8> s) =>
      allocate<Signature>().ref
        ..r_b8 = r_b8
        ..s = s;
}

class Point extends Struct {
  //@ffi.Pointer()
  Pointer<Uint8> x;

  //@ffi.Pointer()
  Pointer<Uint8> y;

  factory Point.allocate(Pointer<Uint8> x, Pointer<Uint8> y) =>
      allocate<Point>().ref
        ..x = x
        ..y = y;
}

// Example of a complex struct (contains strings and other structs)
/*class Place extends ffi.Struct {
  //@ffi.Pointer<>()
  ffi.Pointer<Utf8> name;

  //@ffi.Pointer()
  ffi.Pointer<Coordinate> coordinate;

  factory Place.allocate(
          ffi.Pointer<Utf8> name, ffi.Pointer<Coordinate> coordinate) =>
      ffi.Pointer<Place>.allocate().load<Place>()
        ..name = name
        ..coordinate = coordinate;
}*/

// C string pointer return function - char *hello_world();
// There's no need for two typedefs here, as both the
// C and Dart functions have the same signature
//typedef hello_world_func = ffi.Pointer<Utf8> Function();

// C string parameter pointer function - char *reverse(char *str, int length);
//typedef reverse_func = ffi.Pointer<Utf8> Function(
//    ffi.Pointer<Utf8> str, ffi.Int32 length);
//typedef Reverse = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> str, int length);

// C struct pointer return function - struct Coordinate *create_coordinate(double latitude, double longitude);
//typedef create_coordinate_func = ffi.Pointer<Signature> Function(
//    ffi.Double latitude, ffi.Double longitude);
//typedef CreateCoordinate = ffi.Pointer<Coordinate> Function(
//    double latitude, double longitude);

// C struct pointer return function - struct Place *create_place(char *name, double latitude, double longitude);
/*typedef create_place_func = ffi.Pointer<Place> Function(
    ffi.Pointer<Utf8> name, ffi.Double latitude, ffi.Double longitude);
typedef CreatePlace = ffi.Pointer<Place> Function(
    ffi.Pointer<Utf8> name, double latitude, double longitude);*/

/*main() {
  final dylib = ffi.DynamicLibrary.open('structs.dylib');

  final helloWorldPointer =
      dylib.lookup<ffi.NativeFunction<hello_world_func>>('hello_world');
  final helloWorld = helloWorldPointer.asFunction<hello_world_func>();
  final messagePointer = helloWorld();
  final message = Utf8.fromUtf8(messagePointer);
  print('$message');

  final reversePointer =
      dylib.lookup<ffi.NativeFunction<reverse_func>>('reverse');
  final reverse = reversePointer.asFunction<Reverse>();
  final reversedMessage = Utf8.fromUtf8(reverse(Utf8.toUtf8('backwards'), 9));
  print('$reversedMessage');

  final createCoordinatePointer = dylib
      .lookup<ffi.NativeFunction<create_coordinate_func>>('create_coordinate');
  final createCoordinate =
      createCoordinatePointer.asFunction<CreateCoordinate>();
  final coordinatePointer = createCoordinate(1.0, 2.0);
  final coordinate = coordinatePointer.load();
  print('Coordinate: ${coordinate.latitude}, ${coordinate.longitude}');

  final createPlacePointer =
      dylib.lookup<ffi.NativeFunction<create_place_func>>('create_place');
  final createPlace = createPlacePointer.asFunction<CreatePlace>();
  final placePointer = createPlace(messagePointer, 3.5, 4.6);
  final place = placePointer.load<Place>();
  final placeName = Utf8.fromUtf8(place.name);
  final placeCoordinate = place.coordinate.load<Coordinate>();
  print(
      'Place is called $placeName at ${placeCoordinate.latitude}, ${placeCoordinate.longitude}');
}*/
