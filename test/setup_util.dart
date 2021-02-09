import 'dart:ffi';
import 'dart:io';

final _dylibPrefix = Platform.isWindows ? '' : 'lib';
final _dylibExtension =
    Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
final _dylibName = '${_dylibPrefix}babyjubjub$_dylibExtension';
DynamicLibrary _dylib;

final EXAMPLES_WEB3_URL = 'http://localhost:8545';
//final EXAMPLES_WEB3_URL =
//    "https://ropsten.infura.io/v3/e2d8687b60b944d58adc96485cbab18c";
final EXAMPLES_WEB3_RDP_URL =
    "wss://ropsten.infura.io/ws/v3/e2d8687b60b944d58adc96485cbab18c";
final EXAMPLES_HERMEZ_API_URL = 'http://localhost:8086';
final EXAMPLES_HERMEZ_ROLLUP_ADDRESS =
    '0x10465b16615ae36F350268eb951d7B0187141D3B';
final EXAMPLES_HERMEZ_WDELAYER_ADDRESS =
    '0x8EEaea23686c319133a7cC110b840d1591d9AeE0';
final EXAMPLES_PRIVATE_KEY1 =
    '451c81d2f92dc77ca53fad01d225becc169f3c3480c7f0fdcc77b6c86f342e03';
final EXAMPLES_PRIVATE_KEY2 =
    '0a3d30ae8b52b30669c9fc7e46eb2d37bec5027087b96130ec5b8564b64e46a8';
final EXAMPLES_PRIVATE_KEY3 =
    '5b8ecba6b2d0320b95a1b442e6029cf08090f31b739fd347f1634d04039876e8';

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
