import 'dart:ffi';
import 'dart:io';

final _dylibPrefix = Platform.isWindows ? '' : 'lib';
final _dylibExtension =
    Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
final _dylibName = '${_dylibPrefix}babyjubjub$_dylibExtension';
DynamicLibrary _dylib;

final EXAMPLES_WEB3_URL = 'http://localhost:8545';
final EXAMPLES_HERMEZ_API_URL = 'http://localhost:8086';
final EXAMPLES_HERMEZ_ROLLUP_ADDRESS =
    '0x10465b16615ae36F350268eb951d7B0187141D3B';
final EXAMPLES_HERMEZ_WDELAYER_ADDRESS =
    '0x8EEaea23686c319133a7cC110b840d1591d9AeE0';
final EXAMPLES_PRIVATE_KEY1 =
    '451c81d2f92dc77ca53fad01d225becc169f3c3480c7f0fdcc77b6c86f342e03';
final EXAMPLES_PRIVATE_KEY2 =
    '0a3d30ae8b52b30669c9fc7e46eb2d37bec5027087b96130ec5b8564b64e46a8';

class SetupUtil {
  static Future<DynamicLibrary> getDylibAsync() async {
    await _ensureInitilizedAsync();
    return _dylib;
  }

  static Future _ensureInitilizedAsync() async {
    if (_dylib != null) {
      return;
    }

    /*_dylib = Platform.isAndroid
        ? DynamicLibrary.open("libbabyjubjub.so")
        : DynamicLibrary.process();*/

    final nativeDir = 'rust';
    await Process.run('cargo', ['build', '--release', '--verbose'],
        workingDirectory: nativeDir);
    final dylibPath =
        '${Directory.current.absolute.path}/$nativeDir/target/release/$_dylibName';
    _dylib = DynamicLibrary.open(Uri.file(dylibPath).toFilePath());
  }
}
