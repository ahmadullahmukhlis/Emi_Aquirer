package com.example.gateway

import jakarta.persistence.*
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.*
import java.time.Instant

enum class EntityStatus { PENDING_APPROVAL, ACTIVE, SUSPENDED, QUARANTINED, RETIRED }
enum class TerminalLifecycle { DISCOVERED, PENDING_APPROVAL, PROVISIONING, ACTIVE, SUSPENDED, QUARANTINED, REPLACED, RETIRED }

@Entity @Table(name = "acquirers", uniqueConstraints = [UniqueConstraint(columnNames = ["institution_code"])])
class AcquirerEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(name = "institution_code", nullable = false, unique = true) var institutionCode: String, @Column(nullable = false) var name: String, @Column(nullable = false) var country: String = "AF", @Column(nullable = false) var routeProfile: String, @Enumerated(EnumType.STRING) @Column(nullable = false) var status: EntityStatus = EntityStatus.PENDING_APPROVAL, @Column(nullable = false) var createdAt: Instant = Instant.now())

@Entity @Table(name = "gateway_merchants", uniqueConstraints = [UniqueConstraint(columnNames = ["merchant_id"])])
class MerchantEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(name = "merchant_id", nullable = false, unique = true) var merchantId: String, @Column(nullable = false) var acquirerId: String, @Column(name = "workspace_id") var workspaceId: String? = null, @Column(nullable = false) var legalName: String, @Column(nullable = false) var displayName: String, @Column(nullable = false) var mcc: String, @Column(nullable = false) var currency: String = "AFN", @Column(nullable = false) var settlementProfile: String, @Enumerated(EnumType.STRING) @Column(nullable = false) var status: EntityStatus = EntityStatus.PENDING_APPROVAL, @Column(nullable = false) var createdAt: Instant = Instant.now())

@Entity @Table(name = "gateway_outlets")
class OutletEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(nullable = false) var merchantId: String, @Column(nullable = false) var name: String, @Column(nullable = false) var timezone: String = "Asia/Kabul", var address: String? = null, @Enumerated(EnumType.STRING) @Column(nullable = false) var status: EntityStatus = EntityStatus.PENDING_APPROVAL)

@Entity @Table(name = "gateway_terminals", uniqueConstraints = [UniqueConstraint(columnNames = ["terminal_id"]), UniqueConstraint(columnNames = ["serial_number"])])
class ManagedTerminalEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(name = "terminal_id", nullable = false, unique = true) var terminalId: String, @Column(name = "serial_number", nullable = false, unique = true) var serialNumber: String, @Column(nullable = false) var merchantId: String, var outletId: String? = null, @Column(nullable = false) var model: String, @Column(nullable = false) var capabilityProfile: String, @Enumerated(EnumType.STRING) @Column(nullable = false) var status: TerminalLifecycle = TerminalLifecycle.DISCOVERED, var certificateThumbprint: String? = null, var configurationVersion: String? = null, var lastSeenAt: Instant? = null, @Column(nullable = false) var createdAt: Instant = Instant.now())

@Entity @Table(name = "gateway_audit_events")
class AuditEventEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(nullable = false) var actor: String, @Column(nullable = false) var action: String, @Column(nullable = false) var entityType: String, @Column(nullable = false) var entityId: String, @Column(nullable = false, length = 1000) var detail: String, @Column(nullable = false) var createdAt: Instant = Instant.now())

/** Settlement destination metadata only. Account numbers and bank credentials remain in the approved vault/provider. */
@Entity @Table(name = "merchant_settlement_accounts", uniqueConstraints = [UniqueConstraint(columnNames = ["merchant_id", "account_reference"])])
class MerchantSettlementAccountEntity(@Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null, @Column(name = "merchant_id", nullable = false) var merchantId: String, @Column(name = "account_reference", nullable = false) var accountReference: String, @Column(nullable = false) var accountHolderName: String, @Column(nullable = false) var bankName: String, @Column(nullable = false) var maskedAccount: String, @Column(nullable = false) var currency: String = "AFN", @Column(nullable = false) var payoutSchedule: String = "NEXT_BUSINESS_DAY", @Column(nullable = false) var status: String = "PENDING_VERIFICATION", @Column(nullable = false) var createdAt: Instant = Instant.now())

interface AcquirerRepository : org.springframework.data.jpa.repository.JpaRepository<AcquirerEntity, String> { fun findByInstitutionCode(institutionCode: String): AcquirerEntity? }
interface MerchantRepository : org.springframework.data.jpa.repository.JpaRepository<MerchantEntity, String> { fun findByMerchantId(merchantId: String): MerchantEntity? }
interface OutletRepository : org.springframework.data.jpa.repository.JpaRepository<OutletEntity, String>
interface ManagedTerminalRepository : org.springframework.data.jpa.repository.JpaRepository<ManagedTerminalEntity, String> { fun findByTerminalId(terminalId: String): ManagedTerminalEntity? }
interface AuditEventRepository : org.springframework.data.jpa.repository.JpaRepository<AuditEventEntity, String>
interface MerchantSettlementAccountRepository : org.springframework.data.jpa.repository.JpaRepository<MerchantSettlementAccountEntity, String> { fun findByMerchantId(merchantId: String): List<MerchantSettlementAccountEntity> }

data class AcquirerRequest(@field:NotBlank val institutionCode: String, @field:NotBlank val name: String, @field:NotBlank val routeProfile: String, val country: String = "AF")
data class MerchantRequest(@field:NotBlank val merchantId: String, @field:NotBlank val acquirerId: String, @field:NotBlank val legalName: String, @field:NotBlank val displayName: String, @field:NotBlank val mcc: String, @field:NotBlank val settlementProfile: String, val currency: String = "AFN")
data class OutletRequest(@field:NotBlank val merchantId: String, @field:NotBlank val name: String, val timezone: String = "Asia/Kabul", val address: String? = null)
data class ManagedTerminalRequest(@field:NotBlank val terminalId: String, @field:NotBlank val serialNumber: String, @field:NotBlank val merchantId: String, @field:NotBlank val model: String, @field:NotBlank val capabilityProfile: String, val outletId: String? = null)
data class TerminalHeartbeatRequest(@field:NotBlank val terminalId: String, @field:NotBlank val serialNumber: String, val applicationVersion: String? = null, val configurationVersion: String? = null)
data class SettlementAccountRequest(@field:NotBlank val merchantId: String, @field:NotBlank val accountReference: String, @field:NotBlank val accountHolderName: String, @field:NotBlank val bankName: String, @field:NotBlank val maskedAccount: String, val currency: String = "AFN", val payoutSchedule: String = "NEXT_BUSINESS_DAY")

@Service
class BackOfficeService(private val acquirers: AcquirerRepository, private val merchants: MerchantRepository, private val outlets: OutletRepository, private val terminals: ManagedTerminalRepository, private val audits: AuditEventRepository, private val settlementAccounts: MerchantSettlementAccountRepository) {
    @Transactional fun createAcquirer(r: AcquirerRequest) = acquirers.save(AcquirerEntity(institutionCode = r.institutionCode.uppercase(), name = r.name, routeProfile = r.routeProfile, country = r.country.uppercase())).also { audit("admin", "CREATE", "ACQUIRER", it.id!!, it.institutionCode) }
    @Transactional fun createMerchant(r: MerchantRequest): MerchantEntity { require(acquirers.findById(r.acquirerId).isPresent) { "Acquirer not found" }; return merchants.save(MerchantEntity(merchantId = r.merchantId, acquirerId = r.acquirerId, legalName = r.legalName, displayName = r.displayName, mcc = r.mcc, settlementProfile = r.settlementProfile, currency = r.currency.uppercase())).also { audit("admin", "CREATE", "MERCHANT", it.id!!, it.merchantId) } }
    @Transactional fun createOutlet(r: OutletRequest): OutletEntity { require(merchants.findByMerchantId(r.merchantId) != null) { "Merchant not found" }; return outlets.save(OutletEntity(merchantId = r.merchantId, name = r.name, timezone = r.timezone, address = r.address)).also { audit("admin", "CREATE", "OUTLET", it.id!!, it.merchantId) } }
    @Transactional fun registerTerminal(r: ManagedTerminalRequest): ManagedTerminalEntity { require(merchants.findByMerchantId(r.merchantId) != null) { "Merchant not found" }; return terminals.save(ManagedTerminalEntity(terminalId = r.terminalId, serialNumber = r.serialNumber, merchantId = r.merchantId, outletId = r.outletId, model = r.model, capabilityProfile = r.capabilityProfile, status = TerminalLifecycle.PENDING_APPROVAL)).also { audit("admin", "REGISTER", "TERMINAL", it.id!!, it.terminalId) } }
    @Transactional fun transitionTerminal(id: String, status: TerminalLifecycle): ManagedTerminalEntity { val terminal = terminals.findById(id).orElseThrow { IllegalArgumentException("Terminal not found") }; terminal.status = status; return terminals.save(terminal).also { audit("admin", "STATUS_$status", "TERMINAL", it.id!!, it.terminalId) } }
    @Transactional fun heartbeat(r: TerminalHeartbeatRequest): Map<String, Any?> { val terminal = terminals.findByTerminalId(r.terminalId) ?: throw IllegalArgumentException("Terminal not found"); require(terminal.serialNumber == r.serialNumber) { "Terminal identity does not match" }; require(terminal.status == TerminalLifecycle.ACTIVE) { "Terminal is not active" }; terminal.lastSeenAt = Instant.now(); terminal.configurationVersion = r.configurationVersion ?: terminal.configurationVersion; terminals.save(terminal); return mapOf("terminalId" to terminal.terminalId, "status" to terminal.status, "configurationVersion" to terminal.configurationVersion, "serverTime" to Instant.now()) }
    @Transactional fun addSettlementAccount(r: SettlementAccountRequest): MerchantSettlementAccountEntity { require(merchants.findByMerchantId(r.merchantId) != null) { "Merchant not found" }; require(r.maskedAccount.contains('*')) { "Only a masked account value may be stored" }; return settlementAccounts.save(MerchantSettlementAccountEntity(merchantId = r.merchantId, accountReference = r.accountReference, accountHolderName = r.accountHolderName, bankName = r.bankName, maskedAccount = r.maskedAccount, currency = r.currency.uppercase(), payoutSchedule = r.payoutSchedule)).also { audit("admin", "CREATE", "SETTLEMENT_ACCOUNT", it.id!!, "${it.merchantId} / ${it.accountReference}") } }
    fun settlementAccounts(merchantId: String?) = if (merchantId.isNullOrBlank()) settlementAccounts.findAll() else settlementAccounts.findByMerchantId(merchantId)
    fun overview() = mapOf("acquirers" to acquirers.findAll(), "merchants" to merchants.findAll(), "outlets" to outlets.findAll(), "terminals" to terminals.findAll(), "settlementAccounts" to settlementAccounts.findAll(), "auditEvents" to audits.findAll().takeLast(100))
    private fun audit(actor: String, action: String, type: String, id: String, detail: String) { audits.save(AuditEventEntity(actor = actor, action = action, entityType = type, entityId = id, detail = detail)) }
}

@RestController @RequestMapping("/api/v1/admin")
class BackOfficeController(private val backOffice: BackOfficeService) {
    @PostMapping("/acquirers") @ResponseStatus(HttpStatus.CREATED) fun acquirer(@Valid @RequestBody r: AcquirerRequest) = backOffice.createAcquirer(r)
    @PostMapping("/merchants") @ResponseStatus(HttpStatus.CREATED) fun merchant(@Valid @RequestBody r: MerchantRequest) = backOffice.createMerchant(r)
    @PostMapping("/outlets") @ResponseStatus(HttpStatus.CREATED) fun outlet(@Valid @RequestBody r: OutletRequest) = backOffice.createOutlet(r)
    @PostMapping("/terminals") @ResponseStatus(HttpStatus.CREATED) fun terminal(@Valid @RequestBody r: ManagedTerminalRequest) = backOffice.registerTerminal(r)
    @PostMapping("/terminals/{id}/activate") fun activate(@PathVariable id: String) = backOffice.transitionTerminal(id, TerminalLifecycle.ACTIVE)
    @PostMapping("/terminals/{id}/suspend") fun suspend(@PathVariable id: String) = backOffice.transitionTerminal(id, TerminalLifecycle.SUSPENDED)
    @PostMapping("/settlement-accounts") @ResponseStatus(HttpStatus.CREATED) fun settlementAccount(@Valid @RequestBody r: SettlementAccountRequest) = backOffice.addSettlementAccount(r)
    @GetMapping("/settlement-accounts") fun settlementAccounts(@RequestParam(required = false) merchantId: String?) = backOffice.settlementAccounts(merchantId)
    @GetMapping("/overview") fun overview() = backOffice.overview()
}

@RestController @RequestMapping("/api/v1/terminals")
class TerminalDeviceController(private val backOffice: BackOfficeService) {
    @PostMapping("/heartbeat") fun heartbeat(@Valid @RequestBody request: TerminalHeartbeatRequest) = backOffice.heartbeat(request)
}
