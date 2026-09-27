package com.example.gateway

import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*
import java.util.concurrent.ConcurrentHashMap

enum class ApsSimulatorScenario { APPROVED, DECLINED, TIMEOUT, DUPLICATE, SWITCH_UNAVAILABLE, MALFORMED_RESPONSE }
data class ApsSimulatorRequest(val scenario: ApsSimulatorScenario, val transactionId: String? = null)

/** Local certification aid only. It never connects to APS and must be disabled outside non-production profiles. */
@Service class ApsSimulatorService {
    private val scenarios = ConcurrentHashMap<String, ApsSimulatorScenario>()
    fun configure(request: ApsSimulatorRequest) { require(!request.transactionId.isNullOrBlank()) { "transactionId is required" }; scenarios[request.transactionId] = request.scenario }
    fun scenario(transactionId: String?) = transactionId?.let { scenarios.remove(it) }
}
@RestController @RequestMapping("/api/v1/admin/aps-simulator") class ApsSimulatorController(private val simulator: ApsSimulatorService) {
    @PostMapping fun configure(@RequestBody request: ApsSimulatorRequest) = simulator.configure(request)
}
