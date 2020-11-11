import 'dart:ffi';
import 'dart:io';

final _dylibPrefix = Platform.isWindows ? '' : 'lib';
final _dylibExtension =
    Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
final _dylibName = '${_dylibPrefix}babyjubjub$_dylibExtension';
DynamicLibrary _dylib;

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
