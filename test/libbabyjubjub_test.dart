import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/libs/circomlib.dart';

void main() async {
  final circomlib = CircomLib(/*lib: await SetupUtil.getDylibAsync()*/);

  test('decompressSignature', () {
    final buf = "helloo";
    final version = circomlib.unpackSignature(buf);
    print('LZ4 version number: $version');
    assert(version == 10902);
  });

  test('pack_signature', () {
    final signature = "helloo";
    //final signature = Uint8ArrayUtils.leBuff2int(buf);
    final version = circomlib.packSignature(signature);
  });
}
