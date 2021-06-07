import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/hermez_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('hermez_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await HermezPlugin.platformVersion, '42');
  });

  /*test('decompressSignature', () async {
    // Allocate and free some native memory with malloc and free.
    /*final pointer = allocate<IntPtr>();
    pointer.value = 3;
    print(pointer.value);
    free(pointer);

    // Use the Utf8 helper to encode null-terminated Utf8 strings in native memory.
    final String myString = "😎👿💬";
    final Pointer<Utf8> charPointer = Utf8.toUtf8(myString);
    print("First byte is: ${charPointer.cast<Uint8>().value}");
    print(Utf8.fromUtf8(charPointer));
    free(charPointer);*/
    Uint8List param = new Uint8List.fromList("prueba".codeUnits);
    expect(nativeDecompressSignature(param), '');
  });*/

  /*test('nativeGreeting', () async {
    expect(nativeGreeting("John Smith"), 'Hello John Smith');
  });*/
}
