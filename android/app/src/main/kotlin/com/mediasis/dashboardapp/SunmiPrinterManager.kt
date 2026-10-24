package com.mediasis.dashboardapp

import android.content.Context
import android.os.Build
import com.sunmi.peripheral.printer.InnerPrinterCallback
import com.sunmi.peripheral.printer.InnerPrinterManager
import com.sunmi.peripheral.printer.InnerResultCallback
import com.sunmi.peripheral.printer.SunmiPrinterService
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

object SunmiPrinterManager {
    @Volatile private var service: SunmiPrinterService? = null
    @Volatile private var binding = false
    @Volatile private var bindingLatch = CountDownLatch(0)

    private val serviceCallback = object : InnerPrinterCallback() {
        override fun onConnected(connectedService: SunmiPrinterService) {
            service = connectedService
            binding = false
            bindingLatch.countDown()
        }

        override fun onDisconnected() {
            service = null
            binding = false
        }
    }

    fun detect(context: Context): Map<String, Any> {
        // A manual retry must not reuse a stale binder cached by SUNMI OS.
        clearService(context)
        var printer = awaitService(context) ?: return mapOf(
            "available" to false,
            "service_status" to "Servicio SUNMI no disponible",
        )
        var printerState = readPrinterState(printer)
        if (printerState == null) {
            clearService(context)
            printer = awaitService(context) ?: return mapOf(
                "available" to false,
                "device_model" to Build.MODEL,
                "service_status" to "No se pudo volver a conectar con el servicio SUNMI",
            )
            printerState = readPrinterState(printer)
        }
        val state = printerState ?: 0
        if (!SunmiPrinterStatePolicy.isAvailableAfterBinding(state)) return mapOf(
            "available" to false,
            "device_model" to Build.MODEL,
            "printer_state" to state,
            "service_status" to stateMessage(state),
        )

        val paper = try {
            if (printer.getPrinterPaper() == 2) "mm80" else "mm58"
        } catch (_: Throwable) {
            "mm58"
        }
        val model = try {
            printer.getPrinterModal().takeIf { it.isNotBlank() } ?: Build.MODEL
        } catch (_: Throwable) {
            Build.MODEL
        }
        return mapOf(
            "available" to true,
            "model" to model,
            "device_model" to Build.MODEL,
            "paper_width" to paper,
            "printer_state" to state,
            "service_status" to stateMessage(state),
        )
    }

    fun print(context: Context, bytes: ByteArray) {
        val printer = awaitService(context)
            ?: throw IllegalStateException("No se pudo conectar con la impresora integrada SUNMI.")
        val state = try { printer.updatePrinterState() } catch (_: Throwable) { 0 }
        if (!SunmiPrinterStatePolicy.canAttemptPrint(state)) {
            throw IllegalStateException(stateMessage(state))
        }

        val completion = CountDownLatch(1)
        val successful = AtomicBoolean(false)
        var failure: String? = null
        val callback = object : InnerResultCallback() {
            override fun onRunResult(isSuccess: Boolean) {
                successful.set(isSuccess)
                if (!isSuccess) failure = "La impresora SUNMI rechazo el trabajo."
                completion.countDown()
            }

            override fun onReturnString(result: String?) {}

            override fun onRaiseException(code: Int, message: String?) {
                failure = messageFor(code, message)
                completion.countDown()
            }

            override fun onPrintResult(code: Int, message: String?) {
                successful.set(code == 0 || code == 1)
                if (!successful.get()) failure = messageFor(code, message)
                completion.countDown()
            }
        }
        try {
            printer.sendRAWData(bytes, callback)
        } catch (error: Throwable) {
            throw IllegalStateException(
                error.message ?: "No se pudo enviar el recibo a la impresora SUNMI.",
            )
        }
        if (!completion.await(12, TimeUnit.SECONDS)) {
            throw IllegalStateException("La impresora SUNMI no respondio a tiempo.")
        }
        if (!successful.get()) {
            throw IllegalStateException(failure ?: "No se pudo imprimir en SUNMI.")
        }
    }

    private fun awaitService(context: Context): SunmiPrinterService? {
        service?.let { return it }
        synchronized(this) {
            service?.let { return it }
            if (!binding) {
                binding = true
                bindingLatch = CountDownLatch(1)
                val started = try {
                    InnerPrinterManager.getInstance().bindService(
                        context.applicationContext,
                        serviceCallback,
                    )
                } catch (_: Throwable) {
                    false
                }
                if (!started) {
                    binding = false
                    bindingLatch.countDown()
                }
            }
        }
        bindingLatch.await(5, TimeUnit.SECONDS)
        return service
    }

    private fun readPrinterState(printer: SunmiPrinterService): Int? = try {
        printer.updatePrinterState()
    } catch (_: Throwable) {
        null
    }

    private fun clearService(context: Context) {
        synchronized(this) {
            try {
                InnerPrinterManager.getInstance().unBindService(
                    context.applicationContext,
                    serviceCallback,
                )
            } catch (_: Throwable) {
                // A stale or disconnected binding may already be gone.
            }
            service = null
            binding = false
            bindingLatch.countDown()
            bindingLatch = CountDownLatch(0)
        }
    }

    private fun stateMessage(state: Int): String = when (state) {
        0 -> "Estado no disponible; realiza una impresion de prueba"
        1 -> "Lista"
        2 -> "Preparando impresion"
        3 -> "La impresora SUNMI presenta un error."
        4 -> "La impresora SUNMI no tiene papel."
        5 -> "La impresora SUNMI esta sobrecalentada."
        6 -> "La tapa de la impresora SUNMI esta abierta."
        7 -> "El cortador de la impresora SUNMI presenta un error."
        8 -> "Cortador recuperado"
        9 -> "No se detecto la marca negra del papel."
        505 -> "Este dispositivo no tiene una impresora SUNMI integrada."
        507 -> "No se pudo actualizar el firmware de la impresora SUNMI."
        else -> "La impresora SUNMI no esta disponible (codigo $state)."
    }

    private fun messageFor(code: Int, message: String?): String {
        val normalized = message?.trim().orEmpty()
        return if (normalized.isNotEmpty()) normalized else stateMessage(code)
    }
}
