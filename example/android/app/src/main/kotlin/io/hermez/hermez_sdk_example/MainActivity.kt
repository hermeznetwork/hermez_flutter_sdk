package io.hermez.hermez_sdk_example

import android.os.Bundle
import android.widget.Button
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister
import io.hermez.hermez_sdk.HermezPlugin

class MainActivity: FlutterActivity() {

    private var engine: FlutterEngine? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegister.registerGeneratedPlugins(flutterEngine)
        engine = flutterEngine

    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val button = findViewById<Button>(R.id.button)
        button.setOnClickListener {
            if (engine != null) {
                (engine!!.plugins.get(HermezPlugin::class.java) as HermezPlugin).init("rinkeby")
            }
        }
    }
}
