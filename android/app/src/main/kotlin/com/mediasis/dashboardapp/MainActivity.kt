package com.mediasis.dashboardapp

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    companion object {
        const val PRINTING_CHANNEL = "com.mediasis.dashboardapp/printing"
        const val PRINTING_PREFS = "mediasis_background_printing"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTING_CHANNEL)
            .setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences(PRINTING_PREFS, MODE_PRIVATE)
                when (call.method) {
                    "synchronize" -> {
                        val locationId = call.argument<String>("business_location_id") ?: ""
                        val printers = call.argument<List<Map<String, Any?>>>("printers") ?: emptyList()
                        val encoded = JSONArray()
                        printers.forEach { printer ->
                            val item = JSONObject()
                            printer.forEach { (key, value) -> item.put(key, value) }
                            encoded.put(item)
                        }
                        preferences.edit()
                            .putString("business_location_id", locationId)
                            .putString("printers", encoded.toString())
                            .apply()
                        result.success(null)
                    }
                    "takeJobs" -> {
                        val raw = preferences.getString("completed_jobs", "[]") ?: "[]"
                        preferences.edit().putString("completed_jobs", "[]").apply()
                        val jobs = mutableListOf<Map<String, Any?>>()
                        val array = JSONArray(raw)
                        for (index in 0 until array.length()) {
                            val item = array.getJSONObject(index)
                            jobs.add(item.keys().asSequence().associateWith { item.opt(it) })
                        }
                        result.success(jobs)
                    }
                    "detectSunmiPrinter" -> {
                        Thread {
                            try {
                                val info = SunmiPrinterManager.detect(applicationContext)
                                runOnUiThread { result.success(info) }
                            } catch (_: Throwable) {
                                runOnUiThread {
                                    result.success(
                                        mapOf(
                                            "available" to false,
                                            "service_status" to "Servicio SUNMI no disponible",
                                        ),
                                    )
                                }
                            }
                        }.start()
                    }
                    "printSunmiBytes" -> {
                        val bytes = call.arguments as? ByteArray
                        if (bytes == null) {
                            result.error("sunmi_arguments", "El recibo no es valido.", null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                SunmiPrinterManager.print(applicationContext, bytes)
                                runOnUiThread { result.success(null) }
                            } catch (error: Throwable) {
                                runOnUiThread {
                                    result.error(
                                        "sunmi_print",
                                        error.message ?: "No se pudo imprimir en SUNMI.",
                                        null,
                                    )
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStart() {
        super.onStart()
        getSharedPreferences(PRINTING_PREFS, MODE_PRIVATE)
            .edit().putBoolean("app_is_active", true).apply()
    }

    override fun onStop() {
        getSharedPreferences(PRINTING_PREFS, MODE_PRIVATE)
            .edit().putBoolean("app_is_active", false).apply()
        super.onStop()
    }
}
