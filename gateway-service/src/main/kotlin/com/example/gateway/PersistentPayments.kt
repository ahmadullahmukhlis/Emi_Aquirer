package com.example.gateway

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID

/** Authoritative financial path: records are committed before a caller receives a result. */
@Service
class PersistentPaymentService(
    private val switch: LocalIso8583Switch,
    private val simulator: ApsSimulatorService,
    private val policy: TransactionPolicy,
    private val risk: AcquirerRiskService,
    private val payments: PaymentRepository,
    private val events: PaymentTransactionEventRepository,
    private val ledger: LedgerEntryRepository,
    private val reversals: ReversalJobRepository,
    private val batches: SettlementBatchRepository
) {
    data class AdminTransaction(
        val transactionId: String,
        val channel: PaymentChannel,
        val operation: PaymentOperation,
        val requestId: String,
        val idempotencyKey: String,
        val merchantId: String,
        val terminalId: String?,
        val amountMinor: Long?,
        val currency: String,
        val status: PaymentStatus,
        val responseCode: String,
        val stan: String,
        val rrn: String?,
        val originalTransactionId: String?,
        val iso8583: Map<String, String>,
        val createdAt: Instant
    )

    @Transactional
    fun submit(channel: PaymentChannel, operation: PaymentOperation, request: PaymentRequest): PaymentResponse {
        policy.validate(channel, operation, request)
        risk.validateEstate(channel, request)
        risk.validateLimit(operation, request)
        payments.findByChannelAndIdempotencyKey(channel, request.idempotencyKey)?.let { existing ->
            events.save(PaymentTransactionEventEntity(transactionId = existing.id, status = existing.status, eventType = "IDEMPOTENCY_REPLAY", detail = "Original request returned without a second financial attempt", correlationId = request.requestId))
            return existing.response()
        }
        if (operation in linkedOperations()) require(!request.originalTransactionId.isNullOrBlank() && payments.existsById(request.originalTransactionId)) { "originalTransactionId is required and must exist" }
        val id = "TXN-" + UUID.randomUUID(); val stan = (100000..999999).random().toString()
        val outcome = when (simulator.scenario(request.requestId)) {
            ApsSimulatorScenario.TIMEOUT, ApsSimulatorScenario.SWITCH_UNAVAILABLE -> PaymentStatus.PENDING to linkedMapOf("mti" to "1100", "field11_stan" to stan, "field39_responseCode" to "96", "recoveryReason" to "Configured APS simulator unknown outcome")
            ApsSimulatorScenario.DECLINED -> PaymentStatus.DECLINED to linkedMapOf("mti" to "1110", "field11_stan" to stan, "field39_responseCode" to "51")
            ApsSimulatorScenario.DUPLICATE -> PaymentStatus.DECLINED to linkedMapOf("mti" to "1110", "field11_stan" to stan, "field39_responseCode" to "811")
            ApsSimulatorScenario.MALFORMED_RESPONSE -> PaymentStatus.PENDING to linkedMapOf("mti" to "1100", "field11_stan" to stan, "field39_responseCode" to "96", "recoveryReason" to "Malformed APS simulator response")
            else -> try { switch.execute(channel, operation, request, stan) } catch (ex: Exception) { PaymentStatus.PENDING to linkedMapOf("mti" to "1100", "field11_stan" to stan, "field41_terminalId" to (request.terminalId ?: "MOBILE"), "field42_merchantId" to request.merchantId, "field39_responseCode" to "96", "recoveryReason" to (ex.message ?: "APS connection outcome unknown")) }
        }
        val (switchStatus, iso) = outcome
        val status = if (operation == PaymentOperation.REVERSAL && switchStatus == PaymentStatus.APPROVED) PaymentStatus.REVERSED else switchStatus
        val entity = PaymentEntity(id, channel, operation, request.requestId, request.idempotencyKey, request.merchantId, request.terminalId, request.amountMinor, request.currency.uppercase(), status, iso.getValue("field39_responseCode"), stan, if (switchStatus == PaymentStatus.APPROVED) (iso["field37_rrn"] ?: UUID.randomUUID().toString().replace("-", "").take(12)) else null, request.originalTransactionId, iso.encode())
        payments.save(entity)
        events.save(PaymentTransactionEventEntity(transactionId = entity.id, status = entity.status, eventType = "APS_RESPONSE", detail = "APS response code ${entity.responseCode}", correlationId = request.requestId))
        if (entity.status == PaymentStatus.PENDING) {
            reversals.save(ReversalJobEntity(originalTransactionId = entity.id, lastError = iso["recoveryReason"] ?: "Outcome unknown after APS send"))
            events.save(PaymentTransactionEventEntity(transactionId = entity.id, status = PaymentStatus.REVERSAL_PENDING, eventType = "REVERSAL_QUEUED", detail = "Automatic recovery queued; do not retry as a new financial transaction", correlationId = request.requestId))
        }
        if (status == PaymentStatus.APPROVED || status == PaymentStatus.REVERSED) postLedger(entity)
        return entity.response()
    }

    @Transactional
    fun markUnknownAndScheduleReversal(transactionId: String, reason: String) {
        val tx = payments.findById(transactionId).orElseThrow { IllegalArgumentException("Transaction not found") }
        if (tx.status !in setOf(PaymentStatus.APPROVED, PaymentStatus.PENDING, PaymentStatus.REVERSAL_PENDING)) return
        reversals.findByOriginalTransactionId(tx.id) ?: reversals.save(ReversalJobEntity(originalTransactionId = tx.id, lastError = reason))
        events.save(PaymentTransactionEventEntity(transactionId = tx.id, status = PaymentStatus.REVERSAL_PENDING, eventType = "REVERSAL_QUEUED", detail = reason))
    }

    @Transactional
    fun closeSettlement(merchantId: String, date: LocalDate): SettlementBatchEntity {
        batches.findByMerchantIdAndBusinessDate(merchantId, date)?.let { return it }
        val rows = payments.findByMerchantId(merchantId).filter { it.createdAt.atZone(ZoneOffset.UTC).toLocalDate() == date && it.status in setOf(PaymentStatus.APPROVED, PaymentStatus.REVERSED) }
        val gross = rows.filter { it.operation != PaymentOperation.REVERSAL }.sumOf { it.amountMinor ?: 0 }
        val refunds = rows.filter { it.status == PaymentStatus.REVERSED }.sumOf { it.amountMinor ?: 0 }
        val fee = (gross * 150L) / 10000L // 1.50% local test settlement profile; replace with merchant fee configuration.
        return batches.save(SettlementBatchEntity("SET-$merchantId-$date", merchantId, date, rows.size, gross, refunds, fee, gross - refunds - fee))
    }
    fun get(id: String) = payments.findById(id).orElseThrow { IllegalArgumentException("Transaction not found") }.response()
    fun timeline(id: String) = events.findByTransactionIdOrderByCreatedAtAsc(id)
    fun adminTransactions() = payments.findAll().sortedByDescending { it.createdAt }.map {
        AdminTransaction(it.id, it.channel, it.operation, it.requestId, it.idempotencyKey, it.merchantId, it.terminalId, it.amountMinor, it.currency, it.status, it.responseCode, it.stan, it.rrn, it.originalTransactionId, it.isoSnapshot.decodeIso(), it.createdAt)
    }
    fun adminSettlements() = batches.findAll().sortedByDescending { it.createdAt }
    fun adminFees() = mapOf(
        "feeRateBps" to 150,
        "feeRatePercent" to 1.50,
        "totalFeesMinor" to batches.findAll().sumOf { it.feeMinor },
        "settlements" to batches.count()
    )
    fun settlementResponse(merchantId: String, date: LocalDate): SettlementResponse { val b = closeSettlement(merchantId, date); return SettlementResponse(b.id, b.merchantId, b.businessDate, b.transactionCount, b.grossMinor, b.refundMinor, b.netMinor, b.status.name) }
    private fun postLedger(tx: PaymentEntity) { val amount = tx.amountMinor ?: return; val reversed = tx.status == PaymentStatus.REVERSED; ledger.save(LedgerEntryEntity(transactionId = tx.id, debitAccount = if (reversed) LedgerAccount.MERCHANT_PAYABLE else LedgerAccount.ACQUIRER_CLEARING, creditAccount = if (reversed) LedgerAccount.ACQUIRER_CLEARING else LedgerAccount.MERCHANT_PAYABLE, amountMinor = amount, currency = tx.currency, entryType = if (reversed) "REVERSAL" else "ACQUIRER_AUTHORIZATION")) }
    private fun linkedOperations() = setOf(PaymentOperation.REVERSAL)
}

private fun Map<String, String>.encode() = entries.joinToString("|") { "${it.key}=${it.value.replace("|", "")}" }
private fun String.decodeIso() = split("|").mapNotNull { val split = it.split("=", limit = 2); if (split.size == 2) split[0] to split[1] else null }.toMap()
private fun PaymentEntity.response() = PaymentResponse(id, status, responseCode, if (status == PaymentStatus.APPROVED) "Approved by local ISO-8583 simulator" else status.name, stan, rrn, isoSnapshot.decodeIso())
