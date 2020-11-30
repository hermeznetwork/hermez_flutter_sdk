import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/libs/circomlib.dart';
import 'package:hermez_plugin/utils/uint8_list_utils.dart';

void main() async {
  final circomlib = CircomLib(/*lib: await SetupUtil.getDylibAsync()*/);

  test('decompressSignature', () {
    final buf = Uint8ArrayUtils.uint8ListfromString("helloo");
    final version = circomlib.unpackSignature(buf);
    print('LZ4 version number: $version');
    assert(version == 10902);
  });

  test('pack_signature', () {
    final buf = Uint8ArrayUtils.uint8ListfromString("helloo");
    final signature = Uint8ArrayUtils.toPointer(buf);
    final version = circomlib.packSignature(signature);
  });
}
