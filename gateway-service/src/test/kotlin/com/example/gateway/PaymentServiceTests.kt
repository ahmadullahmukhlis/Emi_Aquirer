package com.example.gateway

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class PaymentServiceTests {
    private val payments = PaymentService(LocalIso8583Switch("local-simulator", "", 0, false, 5000, 30000))

    @Test
    fun `mobile and pos transactions map to iso and settle locally`() {
        val pos = payments.submit(PaymentChannel.POS, PaymentOperation.PURCHASE, PaymentRequest("r1", "idempotency-1", "merchant-1", "POS-1", 1500, "AFN", cardToken = "card-token"))
        val mobile = payments.submit(PaymentChannel.MOBILE, PaymentOperation.PURCHASE, PaymentRequest("r2", "idempotency-2", "merchant-1", amountMinor = 500, cardToken = "card-token"))

        assertEquals(PaymentStatus.APPROVED, pos.status)
        assertEquals("1100", pos.iso8583["mti"])
        assertEquals("POS", pos.iso8583["field60_channel"])
        assertEquals(pos.transactionId, payments.submit(PaymentChannel.POS, PaymentOperation.PURCHASE, PaymentRequest("r3", "idempotency-1", "merchant-1", "POS-1", 1500)).transactionId)
        val settlement = payments.settlement("merchant-1", java.time.LocalDate.now(java.time.ZoneOffset.UTC))
        assertEquals(2, settlement.transactionCount)
        assertEquals(2000, settlement.netMinor)
        assertEquals("CLOSED_LOCAL", settlement.status)
        assertEquals("MOBILE", mobile.iso8583["field60_channel"])
    }
}
