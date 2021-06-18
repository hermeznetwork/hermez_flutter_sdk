package io.hermez.hermez_sdk

import android.app.Activity
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** HermezPlugin */
class HermezPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  //private lateinit var methodHandler: CustomMethodHandler
  private lateinit var mActivityBinding: ActivityPluginBinding

  private fun initChannels(messenger: BinaryMessenger) {
    channel = MethodChannel(messenger, "hermez_sdk"/*Channel.MY_METHOD_CHANNEL*/)
    //methodHandler = CustomMethodHandler(null)
    channel.setMethodCallHandler(this/*authMethodHandler*/)
  }

  private fun teardownChannels() {
    channel.setMethodCallHandler(null)
    //channel = null
  }

  private fun setupActivity(activity: Activity) {
    //channel.setActivity(activity)
  }

  private fun teardownActivity() {
    //methodChannel.setActivity(null)
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    initChannels(flutterPluginBinding.binaryMessenger)
    /*channel = MethodChannel(flutterPluginBinding.binaryMessenger,"hermez_sdk" )
    channel.setMethodCallHandler(this)*/
    /*channel.invokeMethod(
      "initializeSDK",
      null,
      object : Result {
        override fun success(response: Any?) {
          val result : Boolean = response as Boolean
          Log.d("HERMEZ_SDK", "success: $result")
        }

        override fun error(code: String?, msg: String?, details: Any?) {
          //result = response
          Log.e("HERMEZ_SDK", "error: $msg")
        }

        override fun notImplemented() {
          Log.e("HERMEZ_SDK", "not implemented: initializeSDK")
        }
      }
    );

    Factory.setup(this, flutterPluginBinding.binaryMessenger)*/

    /*GeneratedPluginRegistrant.registerWith(this)
    MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
      object : MethodCallHandler() {
        @Override
        fun onMethodCall(call: MethodCall, result: Result) {
          System.out.println("CALL_METHOD::" + call.method)
          // Note: this method is invoked on the main thread.
          if (call.method.equals("setAlarm")) {
            val batteryLevel: Int = setAlarm()
            if (batteryLevel != -1) {
              result.success(true)
            } else {
              result.error("UNAVAILABLE", "Battery level not available.", null)
            }
          } else {
            result.notImplemented()
          }
        }
      })*/

  }

  fun registerWith(registrar: Registrar) {
    val myPlugin = HermezPlugin()
    myPlugin.initChannels(registrar.messenger())
    myPlugin.setupActivity(registrar.activity())
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "initSDK") {
      result.notImplemented()
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    // Debug here for errors.
    mActivityBinding = binding
    setupActivity(mActivityBinding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    teardownActivity()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    mActivityBinding = binding
    setupActivity(mActivityBinding.activity)
  }

  override fun onDetachedFromActivity() {
    teardownActivity()
  }

  fun init(environment: String) {
    channel.invokeMethod("init", environment, object : Result {
      override fun success(response: Any?) {
        val result : Boolean = response as Boolean
        Log.d("HERMEZ_SDK", "success: $result")
      }

      override fun error(code: String?, msg: String?, details: Any?) {
        //result = response
        Log.e("HERMEZ_SDK", "error: $msg")
      }

      override fun notImplemented() {
        Log.e("HERMEZ_SDK", "not implemented: init")
      }
    })
  }

  public fun isInitialized() {
    channel.invokeMethod("isInitialized", null, object : Result {
      override fun success(response: Any?) {
        val result : Boolean = response as Boolean
        Log.d("HERMEZ_SDK", "success isInitialized: $result")
      }

      override fun error(code: String?, msg: String?, details: Any?) {
        //result = response
        Log.e("HERMEZ_SDK", "error isInitialized: $msg")
      }

      override fun notImplemented() {
        Log.e("HERMEZ_SDK", "not implemented: isInitialized")
      }
    })
  }


  private companion object Factory {
    fun setup(plugin: HermezPlugin, binaryMessenger: BinaryMessenger) {
      //plugin.synth = Synth()
      //plugin.synth.start()
    }
  }
}
