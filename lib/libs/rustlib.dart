import 'dart:ffi';
import 'dart:io' show Platform;

DynamicLibrary load({String basePath = ''}) {
  if (Platform.isAndroid /*|| Platform.isLinux*/) {
    return DynamicLibrary.open('${basePath}libbabyjubjub.so');
  } else if (Platform.isIOS) {
    // iOS is statically linked, so it is the same as the current process
    return DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    //return DynamicLibrary.open('${basePath}libbabyjubjub.dylib');
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  } else if (Platform.isWindows) {
    //return DynamicLibrary.open('${basePath}libbabyjubjub.dll');
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  } else {
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  }
}

class NotSupportedPlatform implements Exception {
  NotSupportedPlatform(String s);
}
