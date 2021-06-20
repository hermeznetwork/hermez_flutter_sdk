import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  initializeAndroidWidgets();
  runApp(Container());
}

MethodChannel get channel {
  const MethodChannel newChannel =
      MethodChannel('io.hermez.hermez_sdk/hermez_sdk');

  final CallbackHandle? callback =
      PluginUtilities.getCallbackHandle(onWidgetUpdate);
  final handle = callback!.toRawHandle();

  newChannel.invokeMethod('initialize', handle);
  //_channel.setMethodCallHandler(nativeHandler);
  return newChannel;
}

void initializeAndroidWidgets() {
  //if (Platform.isAndroid) {
  // Intialize flutter
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('io.hermez.hermez_sdk/hermez_sdk');
  channel.setMethodCallHandler(_handleMethod);

  /*final CallbackHandle? callback =
      PluginUtilities.getCallbackHandle(onWidgetUpdate);
  final handle = callback!.toRawHandle();

  channel.invokeMethod('initialize', handle);*/
  //}
}

Future<dynamic> _handleMethod(MethodCall call) async {
  switch (call.method) {
    case "message":
      debugPrint(call.arguments);
      return new Future.value("");
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
