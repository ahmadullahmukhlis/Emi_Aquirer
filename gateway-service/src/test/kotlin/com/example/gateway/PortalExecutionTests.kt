package com.example.gateway

import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import org.mockito.Mockito.*

class PortalExecutionTests {
    @Test fun `reject missing service credentials before purchase execution`() {
        val service = mock(PortalExecutionService::class.java)
        val controller = PortalExecutionController(service, "a".repeat(64))
        val request = PortalPurchaseRequest("pay_" + "a".repeat(32), "idem", "merchant", 100, "AFN", mode = "test")
        assertThrows(SecurityException::class.java) { controller.purchase(null, request) }
        assertThrows(SecurityException::class.java) { controller.purchase("invalid", request) }
        verifyNoInteractions(service)
    }
    @Test fun `test execution cannot silently become a live approval`() {
        val repository = mock(PortalExecutionRepository::class.java)
        val service = PortalExecutionService(repository)
        assertThrows(IllegalArgumentException::class.java) {
            service.purchase(PortalPurchaseRequest("pay_" + "a".repeat(32), "idem", "merchant", 100, "AFN", mode = "live"))
        }
        verifyNoInteractions(repository)
    }
    @Test fun `persisted replay returns original and rejects amount change`() {
        val repository = mock(PortalExecutionRepository::class.java)
        val row = PortalExecution("pay_" + "a".repeat(32), "idem", 100, "AFN", "merchant", "APPROVED", "000")
        `when`(repository.findByIdempotencyKey("idem")).thenReturn(row)
        val service = PortalExecutionService(repository)
        val request = PortalPurchaseRequest(row.id,"idem","merchant",100,"AFN",mode="test")
        assertEquals(row.id, service.purchase(request)["transactionId"])
        assertThrows(IllegalArgumentException::class.java) { service.purchase(request.copy(amountMinor=200)) }
    }
}
