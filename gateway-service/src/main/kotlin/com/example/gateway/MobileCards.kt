package com.example.gateway

import jakarta.persistence.*
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Positive
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.*
import java.time.Instant
import java.util.UUID

@Entity @Table(name = "mobile_registered_cards")
class MobileCardEntity(
    @Id var id: String = "CARD-" + UUID.randomUUID(),
    @Column(name = "owner_id", nullable = false) var ownerId: String,
    @Column(name = "provider_token", nullable = false, unique = true) var providerToken: String,
    @Column(name = "masked_pan", nullable = false) var maskedPan: String,
    @Column(nullable = false) var brand: String,
    @Column(name = "holder_name", nullable = false) var holderName: String,
    @Column(name = "expiry_month", nullable = false) var expiryMonth: Int,
    @Column(name = "expiry_year", nullable = false) var expiryYear: Int,
    @Column(nullable = false) var active: Boolean = true,
    @Column(name = "created_at", nullable = false) var createdAt: Instant = Instant.now()
)
interface MobileCardRepository : JpaRepository<MobileCardEntity, String> { fun findByOwnerIdAndActiveTrue(ownerId: String): List<MobileCardEntity> }

data class RegisterMobileCardRequest(@field:NotBlank val providerToken: String, @field:NotBlank val maskedPan: String, @field:NotBlank val brand: String, @field:NotBlank val holderName: String, val expiryMonth: Int, val expiryYear: Int)
data class MobileCardView(val id: String, val maskedPan: String, val brand: String, val holderName: String, val expiryMonth: Int, val expiryYear: Int, val active: Boolean)
/** Intentionally not a data class: prevents accidental full-PAN rendering through generated toString(). */
class CardToCardRequest {
    @field:NotBlank lateinit var requestId: String
    @field:NotBlank lateinit var idempotencyKey: String
    @field:NotBlank lateinit var sourceCardId: String
    @field:NotBlank lateinit var recipientPan: String
    @field:Positive var amountMinor: Long = 0
    var currency: String = "AFN"
    var note: String? = null
}
class CardWalletRequest {
    @field:NotBlank lateinit var requestId: String
    @field:NotBlank lateinit var idempotencyKey: String
    @field:NotBlank lateinit var cardId: String
    @field:NotBlank lateinit var operation: String
    @field:Positive var amountMinor: Long = 0
    var currency: String = "AFN"
}

@Service
class MobileCardService(private val cards: MobileCardRepository, private val payments: PersistentPaymentService) {
    fun list(owner: String) = cards.findByOwnerIdAndActiveTrue(owner).map { it.view() }
    fun register(owner: String, request: RegisterMobileCardRequest): MobileCardView {
        require(request.maskedPan.matches(Regex("^[0-9*•\\s-]{8,25}$")) && request.maskedPan.count(Char::isDigit) <= 10) { "Only a masked or truncated PAN may be stored" }
        require(request.expiryMonth in 1..12 && request.expiryYear >= 2026) { "Valid card expiry is required" }
        return cards.save(MobileCardEntity(ownerId = owner, providerToken = request.providerToken.trim(), maskedPan = request.maskedPan.trim(), brand = request.brand.trim(), holderName = request.holderName.trim(), expiryMonth = request.expiryMonth, expiryYear = request.expiryYear)).view()
    }
    fun remove(owner: String, id: String) { val card = owned(owner, id); card.active = false; cards.save(card) }
    fun transfer(owner: String, request: CardToCardRequest): PaymentResponse {
        val pan = request.recipientPan.filter(Char::isDigit)
        require(pan.length in 13..19 && luhn(pan)) { "Recipient card number is invalid" }
        require(request.note == null || request.note!!.length <= 140) { "Note must not exceed 140 characters" }
        val source = owned(owner, request.sourceCardId)
        val sanitized = PaymentRequest(request.requestId, request.idempotencyKey, "CARD_NETWORK", amountMinor = request.amountMinor, currency = request.currency, cardToken = source.providerToken, maskedPan = "${pan.take(6)}******${pan.takeLast(4)}")
        // recipientPan is supplied to the switch call only. PersistentPaymentService removes field 2 before storing snapshots.
        return payments.submit(PaymentChannel.MOBILE, PaymentOperation.CARD_TO_CARD, sanitized, pan)
    }
    fun cardWallet(owner: String, request: CardWalletRequest): PaymentResponse {
        val type = try { PaymentOperation.valueOf(request.operation.uppercase()) } catch (_: IllegalArgumentException) { throw IllegalArgumentException("Unsupported card/wallet operation") }
        require(type in setOf(PaymentOperation.CARD_TO_WALLET, PaymentOperation.WALLET_TO_CARD)) { "Only card-to-wallet and wallet-to-card are allowed" }
        val card = owned(owner, request.cardId)
        val payment = PaymentRequest(request.requestId, request.idempotencyKey, "CARD_NETWORK", amountMinor = request.amountMinor, currency = request.currency, cardToken = card.providerToken, maskedPan = card.maskedPan)
        return payments.submit(PaymentChannel.MOBILE, type, payment)
    }
    private fun owned(owner: String, id: String) = cards.findById(id).orElseThrow { IllegalArgumentException("Source card not found") }.also { require(it.ownerId == owner && it.active) { "Source card is unavailable" } }
    private fun luhn(value: String): Boolean { var sum = 0; var alternate = false; for (i in value.length - 1 downTo 0) { var digit = value[i].digitToInt(); if (alternate) { digit *= 2; if (digit > 9) digit -= 9 }; sum += digit; alternate = !alternate }; return sum % 10 == 0 }
    private fun MobileCardEntity.view() = MobileCardView(id, maskedPan, brand, holderName, expiryMonth, expiryYear, active)
}

@RestController @RequestMapping("/api/v1/mobile")
class MobileCardController(private val service: MobileCardService, private val developerAuth: DeveloperAuthService) {
    private fun owner(authorization: String?): String { val token = authorization?.removePrefix("Bearer ") ?: throw SecurityException("API key is required"); return developerAuth.validate(token) ?: throw SecurityException("API key is invalid or expired") }
    @GetMapping("/cards") fun cards(@RequestHeader("Authorization", required = false) authorization: String?) = service.list(owner(authorization))
    @PostMapping("/cards") @ResponseStatus(HttpStatus.CREATED) fun register(@RequestHeader("Authorization", required = false) authorization: String?, @Valid @RequestBody request: RegisterMobileCardRequest) = service.register(owner(authorization), request)
    @DeleteMapping("/cards/{id}") @ResponseStatus(HttpStatus.NO_CONTENT) fun remove(@RequestHeader("Authorization", required = false) authorization: String?, @PathVariable id: String) = service.remove(owner(authorization), id)
    @PostMapping("/card-to-card") @ResponseStatus(HttpStatus.CREATED) fun transfer(@RequestHeader("Authorization", required = false) authorization: String?, @Valid @RequestBody request: CardToCardRequest) = service.transfer(owner(authorization), request)
    @PostMapping("/card-wallet") @ResponseStatus(HttpStatus.CREATED) fun cardWallet(@RequestHeader("Authorization", required = false) authorization: String?, @Valid @RequestBody request: CardWalletRequest) = service.cardWallet(owner(authorization), request)
}
