package com.example.gateway

import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Positive
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*
import java.time.Instant
import java.time.LocalDate
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.net.InetSocketAddress
import java.net.Socket
import javax.net.ssl.SSLSocketFactory
import org.springframework.beans.factory.annotation.Value

enum class PaymentChannel { MOBILE, POS }
/** APS acquirer catalogue only.  Issuer products, card production and generic card lifecycle operations are deliberately not accepted here. */
enum class PaymentOperation { BALANCE_INQUIRY, PURCHASE, CASH_IN, CASH_OUT, PAYMENT_INFO, SAVE_PAYMENT, WALLET_TO_CARD, CARD_TO_WALLET, CARD_TO_CARD, CARD_TITLE_FETCH, CROSS_CURRENCY, REVERSAL }
enum class PaymentStatus { APPROVED, DECLINED, PENDING, REVERSAL_PENDING, REVERSED }

data class PaymentRequest(
    @field:NotBlank val requestId: String, @field:NotBlank val idempotencyKey: String,
    @field:NotBlank val merchantId: String, val terminalId: String? = null,
    @field:Positive val amountMinor: Long? = null, val currency: String = "AFN",
    val cardToken: String? = null, val maskedPan: String? = null, val originalTransactionId: String? = null
)
data class PaymentResponse(val transactionId: String, val status: PaymentStatus, val responseCode: String, val message: String, val stan: String, val rrn: String?, val iso8583: Map<String, String>)
data class SettlementResponse(val batchId: String, val merchantId: String, val businessDate: LocalDate, val transactionCount: Int, val grossMinor: Long, val refundMinor: Long, val netMinor: Long, val status: String)

private data class StoredPayment(val id: String, val channel: PaymentChannel, val operation: PaymentOperation, val request: PaymentRequest, val status: PaymentStatus, val stan: String, val rrn: String?, val iso: Map<String, String>, val createdAt: Instant = Instant.now())

/** Local, deterministic SmartVista-compatible boundary. It creates ISO fields but never sends card data over a network. */
@Service
class LocalIso8583Switch(
    @param:Value("\${gateway.switch.mode:local-simulator}") private val mode: String,
    @param:Value("\${gateway.switch.host:}") private val host: String,
    @param:Value("\${gateway.switch.port:0}") private val port: Int,
    @param:Value("\${gateway.switch.tls:false}") private val tls: Boolean,
    @param:Value("\${gateway.switch.connect-timeout-ms:5000}") private val connectTimeoutMs: Int,
    @param:Value("\${gateway.switch.read-timeout-ms:30000}") private val readTimeoutMs: Int
) {
    private val codec = Iso8583Codec()
    fun execute(channel: PaymentChannel, operation: PaymentOperation, request: PaymentRequest, stan: String): Pair<PaymentStatus, Map<String, String>> {
        // APS H2H v1.6 acquirer defaults. Production transport/reversal details remain in a certified profile.
        val mti = when (operation) { PaymentOperation.REVERSAL -> "0400"; PaymentOperation.CARD_TITLE_FETCH -> "1600"; else -> "1100" }
        val processingCode = mapOf(
            PaymentOperation.PURCHASE to "000000", PaymentOperation.CASH_IN to "100000",
            PaymentOperation.CASH_OUT to "010000", PaymentOperation.BALANCE_INQUIRY to "310000",
            PaymentOperation.PAYMENT_INFO to "500000", PaymentOperation.SAVE_PAYMENT to "500000",
            PaymentOperation.WALLET_TO_CARD to "290000", PaymentOperation.CARD_TO_WALLET to "500000",
            PaymentOperation.CARD_TITLE_FETCH to "350000", PaymentOperation.CROSS_CURRENCY to "100000"
        )[operation] ?: "CONFIGURE"
        val transactionTag = mapOf(
            PaymentOperation.PURCHASE to "774", PaymentOperation.CASH_IN to "618", PaymentOperation.CASH_OUT to "700",
            PaymentOperation.BALANCE_INQUIRY to "702", PaymentOperation.PAYMENT_INFO to "511", PaymentOperation.SAVE_PAYMENT to "508",
            PaymentOperation.WALLET_TO_CARD to "785", PaymentOperation.CARD_TO_WALLET to "781",
            PaymentOperation.CARD_TO_CARD to "689", PaymentOperation.CARD_TITLE_FETCH to "651", PaymentOperation.CROSS_CURRENCY to "700"
        )[operation] ?: "CONFIGURE"
        val approved = request.amountMinor == null || request.amountMinor <= 10_000_000_00L
        val fields = linkedMapOf("mti" to mti, "field3_processingCode" to processingCode, "field4_amount" to (request.amountMinor ?: 0).toString().padStart(12, '0'), "field11_stan" to stan, "field41_terminalId" to (request.terminalId ?: "MOBILE"), "field42_merchantId" to request.merchantId, "field48.002_transactionType" to transactionTag, "field49_currency" to request.currency, "field60_channel" to channel.name, "field39_responseCode" to if (approved) "00" else "51")
        return if (mode.equals("tcp", ignoreCase = true)) executeTcp(mti, fields) else (if (approved) PaymentStatus.APPROVED else PaymentStatus.DECLINED) to fields
    }
    private fun executeTcp(mti: String, fields: Map<String, String>): Pair<PaymentStatus, Map<String, String>> {
        require(host.isNotBlank() && port in 1..65535) { "National switch host and port must be configured" }
        val isoFields = fields.mapNotNull { (key, value) -> Regex("field(\\d+)_.*").matchEntire(key)?.groupValues?.get(1)?.toInt()?.let { it to value.trim() } }.toMap()
        val socket: Socket = if (tls) SSLSocketFactory.getDefault().createSocket() else Socket()
        socket.use {
            it.connect(InetSocketAddress(host, port), connectTimeoutMs); it.soTimeout = readTimeoutMs
            val payload = codec.pack(mti, isoFields); val output = it.getOutputStream(); output.write(payload.size ushr 8); output.write(payload.size and 0xff); output.write(payload); output.flush()
            val input = it.getInputStream(); val size = (input.read() shl 8) or input.read(); require(size in 20..8192) { "Invalid national switch response frame" }
            val response = input.readNBytes(size); require(response.size == size) { "Incomplete national switch response" }
            val (responseMti, decoded) = codec.unpack(response); val mapped = decoded.mapKeys { (field, _) -> when (field) { 37 -> "field37_rrn"; 39 -> "field39_responseCode"; 38 -> "field38_authorizationId"; else -> "field${field}" } }.toMutableMap(); mapped["mti"] = responseMti
            val code = decoded[39] ?: "96"; return (if (code == "00") PaymentStatus.APPROVED else PaymentStatus.DECLINED) to mapped
        }
    }
}

@Service
class PaymentService(private val switch: LocalIso8583Switch) {
    private val transactions = ConcurrentHashMap<String, StoredPayment>()
    private val idempotency = ConcurrentHashMap<String, String>()

    fun submit(channel: PaymentChannel, operation: PaymentOperation, request: PaymentRequest): PaymentResponse {
        require(channel != PaymentChannel.POS || !request.terminalId.isNullOrBlank()) { "terminalId is required for POS" }
        val idempotencyId = "$channel:${request.idempotencyKey}"
        idempotency[idempotencyId]?.let { return response(transactions.getValue(it)) }
        if (operation == PaymentOperation.REVERSAL) require(!request.originalTransactionId.isNullOrBlank() && transactions.containsKey(request.originalTransactionId)) { "originalTransactionId is required and must exist" }
        val id = "TXN-" + UUID.randomUUID(); val stan = (100000..999999).random().toString()
        val (status, iso) = switch.execute(channel, operation, request, stan)
        val finalStatus = if (operation == PaymentOperation.REVERSAL && status == PaymentStatus.APPROVED) PaymentStatus.REVERSED else status
        val record = StoredPayment(id, channel, operation, request, finalStatus, stan, if (status == PaymentStatus.APPROVED) UUID.randomUUID().toString().replace("-", "").take(12) else null, iso)
        transactions[id] = record; idempotency.putIfAbsent(idempotencyId, id)
        return response(record)
    }
    fun settlement(merchantId: String, businessDate: LocalDate): SettlementResponse {
        val rows = transactions.values.filter { it.request.merchantId == merchantId && it.createdAt.atZone(java.time.ZoneOffset.UTC).toLocalDate() == businessDate && it.status in setOf(PaymentStatus.APPROVED, PaymentStatus.REVERSED) }
        val gross = rows.filter { it.operation != PaymentOperation.REVERSAL }.sumOf { it.request.amountMinor ?: 0 }; val refunds = rows.filter { it.status == PaymentStatus.REVERSED }.sumOf { it.request.amountMinor ?: 0 }
        return SettlementResponse("SET-${merchantId}-${businessDate}", merchantId, businessDate, rows.size, gross, refunds, gross - refunds, "CLOSED_LOCAL")
    }
    fun get(id: String) = response(transactions[id] ?: throw IllegalArgumentException("Transaction not found"))
    private fun response(r: StoredPayment) = PaymentResponse(r.id, r.status, r.iso.getValue("field39_responseCode"), if (r.status == PaymentStatus.APPROVED) "Approved by local ISO-8583 simulator" else r.status.name, r.stan, r.rrn, r.iso)
}

@RestController
@RequestMapping("/api/v1")
class GatewayController(
    private val payments: PersistentPaymentService,
    private val developerAuth: DeveloperAuthService,
    private val apps: DeveloperAppRepository,
    private val merchants: MerchantRepository
) {
    private fun authorizePurchase(authorization: String?, merchantId: String) {
        val token = authorization?.removePrefix("Bearer ") ?: throw SecurityException("API key is required")
        val appId = developerAuth.validate(token) ?: throw SecurityException("API key is invalid or expired")
        val app = apps.findById(appId).orElseThrow { SecurityException("Integration application is not available") }
        val merchant = merchants.findByMerchantId(merchantId) ?: throw SecurityException("Merchant is not available")
        require(merchant.workspaceId == app.organizationId) { "This API key is not authorized for the merchant" }
    }
    /** Gateway is an execution boundary. Developer accounts, keys and dashboards belong to the Portal. */
    @PostMapping("/mobile/transactions/purchase") @ResponseStatus(HttpStatus.CREATED)
    fun mobilePurchase(@RequestHeader("Authorization", required = false) authorization: String?, @Valid @RequestBody request: PaymentRequest): PaymentResponse { authorizePurchase(authorization, request.merchantId); return payments.submit(PaymentChannel.MOBILE, PaymentOperation.PURCHASE, request) }
    @PostMapping("/transactions/purchase") @ResponseStatus(HttpStatus.CREATED)
    fun purchase(@RequestHeader("Authorization", required = false) authorization: String?, @Valid @RequestBody request: PaymentRequest): PaymentResponse { authorizePurchase(authorization, request.merchantId); return payments.submit(if (request.terminalId.isNullOrBlank()) PaymentChannel.MOBILE else PaymentChannel.POS, PaymentOperation.PURCHASE, request) }
    @GetMapping("/transactions/{id}") fun transaction(@PathVariable id: String) = payments.get(id)
    @GetMapping("/transactions/{id}/timeline") fun timeline(@PathVariable id: String) = payments.timeline(id)
}

@RestControllerAdvice
class GatewayErrors { @ExceptionHandler(IllegalArgumentException::class) @ResponseStatus(HttpStatus.BAD_REQUEST) fun invalid(ex: IllegalArgumentException) = mapOf("message" to (ex.message ?: "Invalid request")) }
