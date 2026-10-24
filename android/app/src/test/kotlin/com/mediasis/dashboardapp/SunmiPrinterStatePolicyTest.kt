package com.mediasis.dashboardapp

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SunmiPrinterStatePolicyTest {
    @Test
    fun boundUnknownAndReadyStatesAreAvailable() {
        for (state in listOf(0, 1, 2, 8)) {
            assertTrue(SunmiPrinterStatePolicy.isAvailableAfterBinding(state))
        }
    }

    @Test
    fun explicitNoPrinterStateIsUnavailable() {
        assertFalse(SunmiPrinterStatePolicy.isAvailableAfterBinding(505))
    }

    @Test
    fun unknownAndReadyStatesMayReachThePrintCallback() {
        for (state in listOf(0, 1, 2, 8)) {
            assertTrue(SunmiPrinterStatePolicy.canAttemptPrint(state))
        }
        for (state in listOf(3, 4, 5, 6, 7, 9, 505, 507)) {
            assertFalse(SunmiPrinterStatePolicy.canAttemptPrint(state))
        }
    }
}
