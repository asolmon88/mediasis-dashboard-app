package com.mediasis.dashboardapp

internal object SunmiPrinterStatePolicy {
    fun isAvailableAfterBinding(state: Int): Boolean = state != 505

    fun canAttemptPrint(state: Int): Boolean = state == 0 || state == 1 || state == 2 || state == 8
}
