package com.example.gateway

import jakarta.persistence.*
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

enum class ApsResponseCategory { APPROVED, CUSTOMER_INPUT, INSUFFICIENT_FUNDS, LIMIT, CARD_RESTRICTED, AUTHENTICATION, SWITCH_UNAVAILABLE, TIMEOUT, DUPLICATE, REVERSAL, FRAUD_SUSPECTED, SYSTEM_ERROR, UNKNOWN }

@Entity @Table(name = "aps_response_codes")
class ApsResponseCodeEntity(@Id var code: String, @Column(nullable = false) var description: String, @Enumerated(EnumType.STRING) @Column(nullable = false) var category: ApsResponseCategory, @Column(nullable = false) var retryable: Boolean = false, @Column(nullable = false) var operationsAction: String = "NONE")
interface ApsResponseCodeRepository : org.springframework.data.jpa.repository.JpaRepository<ApsResponseCodeEntity, String>

@Service class ApsResponseCodeService(private val repository: ApsResponseCodeRepository) {
    fun classify(code: String): ApsResponseCodeEntity = repository.findById(code).orElse(ApsResponseCodeEntity(code, "Unrecognised APS response code", ApsResponseCategory.UNKNOWN, false, "ALERT_OPERATIONS"))
    fun all() = repository.findAll()
}
@RestController @RequestMapping("/api/v1/admin/aps-response-codes") class ApsResponseCodeController(private val service: ApsResponseCodeService) { @GetMapping fun all() = service.all() }
