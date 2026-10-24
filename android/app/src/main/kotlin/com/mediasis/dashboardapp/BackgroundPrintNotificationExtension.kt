package com.mediasis.dashboardapp

import androidx.annotation.Keep
import com.onesignal.notifications.INotificationReceivedEvent
import com.onesignal.notifications.INotificationServiceExtension
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.Socket
import java.net.URL
import java.time.Instant

@Keep
class BackgroundPrintNotificationExtension : INotificationServiceExtension {
    override fun onNotificationReceived(event: INotificationReceivedEvent) {
        val data = event.notification.additionalData ?: return
        if (data.optString("type") != "new_order") return
        val preferences = event.context.getSharedPreferences(
            MainActivity.PRINTING_PREFS,
            android.content.Context.MODE_PRIVATE,
        )
        if (preferences.getBoolean("app_is_active", false)) return

        event.preventDefault()
        Thread {
            try {
                printForConfiguredPrinters(event.context, data)
            } finally {
                event.notification.display()
            }
        }.start()
    }

    private fun printForConfiguredPrinters(context: android.content.Context, data: JSONObject) {
        val orderId = data.optString("order_id")
        val locationId = data.optString("business_location_id")
        val endpoint = data.optString("print_endpoint")
        val authorization = data.optString("print_authorization")
        if (orderId.isBlank() || locationId.isBlank() || endpoint.isBlank() || authorization.isBlank()) return

        val preferences = context.getSharedPreferences(MainActivity.PRINTING_PREFS, android.content.Context.MODE_PRIVATE)
        if (preferences.getString("business_location_id", "") != locationId) return
        val printers = JSONArray(preferences.getString("printers", "[]") ?: "[]")
        val printedKeys = preferences.getStringSet("printed_keys", emptySet())?.toMutableSet() ?: mutableSetOf()
        for (index in 0 until printers.length()) {
            val printer = printers.getJSONObject(index)
            val key = "$locationId|$orderId|${printer.optString("id")}"
            if (printedKeys.contains(key)) continue
            try {
                val bytes = fetchReceipt(endpoint, authorization, printer)
                printWithRetry(context, printer, bytes)
                printedKeys.add(key)
                saveJob(preferences, orderId, locationId, printer, "printed", null)
            } catch (error: Throwable) {
                saveJob(preferences, orderId, locationId, printer, "failed", error.message ?: "No se pudo imprimir")
            }
        }
        preferences.edit().putStringSet("printed_keys", printedKeys).apply()
    }

    private fun printWithRetry(
        context: android.content.Context,
        printer: JSONObject,
        bytes: ByteArray,
    ) {
        try {
            sendToPrinter(context, printer, bytes)
        } catch (_: Throwable) {
            Thread.sleep(2000)
            sendToPrinter(context, printer, bytes)
        }
    }

    private fun sendToPrinter(
        context: android.content.Context,
        printer: JSONObject,
        bytes: ByteArray,
    ) {
        if (printer.optString("connection_type") == "sunmiBuiltIn") {
            SunmiPrinterManager.print(context, bytes)
            return
        }
        Socket().use { socket ->
            socket.connect(
                java.net.InetSocketAddress(
                    printer.getString("host"),
                    printer.optInt("port", 9100),
                ),
                5000,
            )
            socket.getOutputStream().apply { write(bytes); flush() }
        }
    }

    private fun fetchReceipt(endpoint: String, authorization: String, printer: JSONObject): ByteArray {
        val connection = URL(endpoint).openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.connectTimeout = 7000
        connection.readTimeout = 12000
        connection.doOutput = true
        connection.setRequestProperty("Content-Type", "application/json")
        val body = JSONObject()
            .put("print_authorization", authorization)
            .put("paper_width", printer.optString("paper_width", "mm80"))
            .put("supports_cutter", printer.optBoolean("supports_cutter", true))
            .put("receipt_format", printer.optString("receipt_format", "visualRaster"))
            .toString().toByteArray()
        connection.outputStream.use { it.write(body) }
        if (connection.responseCode !in 200..299) throw IllegalStateException("El servidor no pudo preparar el recibo")
        return connection.inputStream.use { it.readBytes() }
    }

    private fun saveJob(
        preferences: android.content.SharedPreferences,
        orderId: String,
        locationId: String,
        printer: JSONObject,
        status: String,
        error: String?,
    ) {
        val jobs = JSONArray(preferences.getString("completed_jobs", "[]") ?: "[]")
        jobs.put(JSONObject()
            .put("id", "native_${System.currentTimeMillis()}_${printer.optString("id")}")
            .put("business_location_id", locationId)
            .put("order_id", orderId)
            .put("printer_id", printer.optString("id"))
            .put("printer_name", printer.optString("name"))
            .put("trigger", "automatic")
            .put("status", status)
            .put("attempted_at", Instant.now().toString())
            .put("error", error))
        preferences.edit().putString("completed_jobs", jobs.toString()).apply()
    }
}
