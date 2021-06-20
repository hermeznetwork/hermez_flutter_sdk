package io.hermez.hermez_sdk_example

import android.os.Bundle
import android.util.Log
import android.widget.Button
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister
import io.hermez.hermez_sdk.HermezPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    companion object {
        const val CHANNEL = "io.hermez.hermez_sdk/hermez_sdk"
    }

    private var engine: FlutterEngine? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d("HERMEZ_SDK", "configureFlutterEngine")
        GeneratedPluginRegister.registerGeneratedPlugins(flutterEngine)
        engine = flutterEngine
        val entrypoint: DartExecutor.DartEntrypoint = DartExecutor.DartEntrypoint.createDefault()
        /*val entrypoint: DartExecutor.DartEntrypoint =
            DartExecutor.DartEntrypoint("lib/hermez_sdk.dart", "hermez_sdk", "initialize");*/
        engine!!.dartExecutor.executeDartEntrypoint(entrypoint)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        //GeneratedPluginRegistrant.registerWith(this)

        /*MethodChannel(flutterView, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("HERMEZ_SDK", "methodCallHandler")
            //if (call.method == "showNativeView") {
            //    val intent = Intent(this, NativeViewActivity::class.java)
            //    startActivity(intent)
            result.success(true)
            /*} else {
                result.notImplemented()
            }*/
        }*/

        // check if flutterEngine is null
        /*if (flutterEngine == null) {
            println(args)
            flutterEngine = FlutterEngine(this, args)
            flutterEngine!!.dartExecutor.executeDartEntrypoint(
                // set which of dart methode will be used here
                DartEntrypoint(FlutterMain.findAppBundlePath(),"myMainDartMethod")
                // to set here the main methode you can use this function to do this
                // inteade of DartEntrypoint(FlutterMain.findAppBundlePath(),"myMainDartMethod")
                // write this mdethode DartEntrypoint.createDefault()
            )
        }*/


        val button = findViewById<Button>(R.id.button)
        button.setOnClickListener {
            if (engine != null) {
                (engine!!.plugins.get(HermezPlugin::class.java) as HermezPlugin).init("rinkeby")
            }
        }
    }
}
