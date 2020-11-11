import 'package:flutter_test/flutter_test.dart';

void main() async {
  //final lz4 = Lz4Lib(lib: await SetupUtil.getDylibAsync());
  test('getVersionNumber', () {
    //final version = lz4.getVersioinNumber();
    print('LZ4 version number: $version');
    assert(version == 10902);
  });
}
