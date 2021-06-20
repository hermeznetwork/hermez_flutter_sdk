import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hermez_sdk/environment.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

/*abstract class AWEvents {
  //Float64List getAudio();
}*/

class HermezSDK {
  static MethodChannel get _channel {
    MethodChannel newChannel =
        const MethodChannel("io.hermez.hermez_sdk/hermez_sdk");
    //_channel.setMethodCallHandler(nativeHandler);
    return newChannel;
  }

  static initialize() {
    _channel.setMethodCallHandler(nativeHandler);
  }

  void initializeAndroidWidgets() {
    if (Platform.isAndroid) {
      // Intialize flutter
      WidgetsFlutterBinding.ensureInitialized();

      const MethodChannel channel =
          MethodChannel('io.hermez.hermez_sdk/hermez_sdk');

      final CallbackHandle? callback =
          PluginUtilities.getCallbackHandle(onWidgetUpdate);
      final handle = callback!.toRawHandle();

      channel.invokeMethod('initialize', handle);
    }
  }

  void onWidgetUpdate() {
    // Intialize flutter
    WidgetsFlutterBinding.ensureInitialized();

    const MethodChannel channel =
        MethodChannel('io.hermez.hermez_sdk/hermez_sdk');

    // If you use dependency injection you will need to inject
    // your objects before using them.

    channel.setMethodCallHandler(
      (call) async {
        final id = call.arguments;

        print('on Dart ${call.method}!');

        // Do your stuff here...
        final result = Random().nextDouble();

        return {
          // Pass back the id of the widget so we can
          // update it later
          'id': id,
          // Some data
          'value': result,
        };
      },
    );
  }

  //static AWEvents _handler;

  /*static setEventHandler(AWEvents handler) {
    _channel.setMethodCallHandler(nativeHandler);
    //_handler = handler;
  }*/

  static Future<dynamic> nativeHandler(MethodCall call) async {
    switch (call.method) {
      case 'init':
        return init(call.arguments);
      case 'isInitialized':
        return isInitialized;
      //return 123.0;
      default:
        return init(call.arguments);
      //throw MissingPluginException('notImplemented');
    }
  }

  static Future<String?> get platformVersion async {
    final String? version =
        await _channel.invokeMethod('getPlatformVersion'); // 3

    return version;
  }

  static Future<dynamic> methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'init':
        return init(call.arguments);
      case 'isInitialized':
        return isInitialized;
      //return 123.0;
      default:
        throw MissingPluginException('notImplemented');
    }
  }

  static Web3Client? _web3Client;
  static EnvParams? _environment;

  /// Sets an environment from a supported environment configuration or from a custom environment object
  ///
  /// @param [String] env - Supported environment name
  /// @param optional [String] web3ApiKey - web3 provider api key
  /// @param optional [EnvParams] envParams - Custom environment object, only used when env value is 'custom'
  static bool init(String environment,
      {String? web3ApiKey, EnvParams? envParams}) {
    // setup environment
    setEnvironment(environment, web3ApiKey, envParams: envParams);
    _environment = getCurrentEnvironment();

    // setup web3 client
    _web3Client = Web3Client(getCurrentEnvironment()!.baseWeb3Url, Client(),
        socketConnector: () {
      return IOWebSocketChannel.connect(getCurrentEnvironment()!.baseWeb3RdpUrl)
          .cast<String>();
    });
    return true;
  }

  static bool get isInitialized {
    return _web3Client != null && _environment != null;
  }

  /// Returns the current web3 client
  ///
  /// @returns [Web3Client] current web3 client
  static Web3Client? get currentWeb3Client {
    return _web3Client;
  }

  /// Returns the current environment
  /// @returns [EnvParams] Contains contract addresses, Hermez API and Batch Explorer urls
  static EnvParams? get currentEnvironment {
    return _environment;
  }

  //static List<Token> get supportedTokens {}
}
