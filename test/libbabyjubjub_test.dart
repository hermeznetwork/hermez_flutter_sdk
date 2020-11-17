import 'package:flutter_test/flutter_test.dart';
import 'package:hermez_plugin/libs/circomlib.dart';
import 'package:hermez_plugin/utils.dart';

import 'setup_util.dart';

void main() async {
  final circomlib = CircomLib(lib: await SetupUtil.getDylibAsync());
  test('decompressSignature', () {
    final buf = getUint8ListFromString("helloo");
    final version = circomlib.decompressSignature(buf);
    print('LZ4 version number: $version');
    assert(version == 10902);
  });
}
