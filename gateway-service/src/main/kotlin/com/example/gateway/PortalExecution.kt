package com.example.gateway

import jakarta.persistence.*
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*
import java.security.MessageDigest
import java.time.Instant

@Entity
@Table(name = "portal_execution", uniqueConstraints = [UniqueConstraint(columnNames = ["idempotency_key"])])
class PortalExecution(
    @Id var id: String,
    @Column(name = "idempotency_key", nullable = false) var idempotencyKey: String,
    var amountMinor: Long,
    var currency: String,
    var merchantId: String,
    var status: String,
    var responseCode: String,
    var createdAt: Instant = Instant.now()
)
interface PortalExecutionRepository : org.springframework.data.jpa.repository.JpaRepository<PortalExecution, String> {
    fun findByIdempotencyKey(idempotencyKey: String): PortalExecution?
}
data class PortalPurchaseRequest(val requestId: String, val idempotencyKey: String, val merchantId: String, val amountMinor: Long, val currency: String, val scenario: String = "approved", val mode: String)

@Service
class PortalExecutionService(private val repository: PortalExecutionRepository) {
    @Synchronized
    fun purchase(r: PortalPurchaseRequest): Map<String, String> {
        require(r.mode == "test") { "Live processing requires a certified funding and authentication adapter" }
        require(r.amountMinor > 0 && r.requestId.matches(Regex("pay_[a-f0-9]{32}"))) { "Invalid purchase" }
        repository.findByIdempotencyKey(r.idempotencyKey)?.let {
            require(it.amountMinor == r.amountMinor && it.currency == r.currency && it.merchantId == r.merchantId) { "Idempotency conflict" }
            return response(it)
        }
        require(r.scenario in setOf("approved", "declined", "pending")) { "Invalid scenario" }
        val status = when (r.scenario) { "declined" -> "DECLINED"; "pending" -> "PENDING"; else -> "APPROVED" }
        return response(repository.save(PortalExecution(r.requestId, r.idempotencyKey, r.amountMinor, r.currency, r.merchantId, status, when(status) { "APPROVED" -> "000"; "DECLINED" -> "116"; else -> "961" })))
    }
    fun get(id: String) = response(repository.findById(id).orElseThrow { IllegalArgumentException("Purchase not found") })
    private fun response(p: PortalExecution) = mapOf("transactionId" to p.id, "status" to p.status, "responseCode" to p.responseCode, "message" to "Sandbox ${p.status.lowercase()}")
}

@RestController
@RequestMapping("/internal/portal/purchases")
class PortalExecutionController(private val service: PortalExecutionService, @Value("\${portal.service-key:}") private val serviceKey: String) {
    private fun authorize(key: String?) {
        if (serviceKey.length < 32 || key == null || !MessageDigest.isEqual(serviceKey.toByteArray(), key.toByteArray())) throw SecurityException("Portal service authentication required")
    }
    @PostMapping fun purchase(@RequestHeader("X-Portal-Service-Key", required = false) key: String?, @RequestBody request: PortalPurchaseRequest): Map<String,String> { authorize(key); return service.purchase(request) }
    @GetMapping("/{id}") fun get(@RequestHeader("X-Portal-Service-Key", required = false) key: String?, @PathVariable id: String): Map<String,String> { authorize(key); return service.get(id) }
}
