package com.clonelab.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.clonelab.app/native"

    companion object {
        init {
            System.loadLibrary("clonelab_native")
        }
    }

    external fun getEngineVersion(): String
    external fun createClone(appPackage: String): Int

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getEngineVersion" -> {
                        try {
                            result.success(getEngineVersion())
                        } catch (e: Exception) {
                            result.error("NATIVE_ERROR", e.message, null)
                        }
                    }
                    "createClone" -> {
                        val packageName = call.argument<String>("package")
                        if (packageName == null) {
                            result.error("INVALID_ARGS", "package missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val pid = createClone(packageName)
                            result.success(pid)
                        } catch (e: Exception) {
                            result.error("NATIVE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}