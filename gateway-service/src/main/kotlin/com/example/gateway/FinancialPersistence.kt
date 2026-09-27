package com.example.gateway

import jakarta.persistence.*
import java.time.Instant
import java.time.LocalDate

@Entity
@Table(name = "payment_transactions", uniqueConstraints = [UniqueConstraint(columnNames = ["channel", "idempotency_key"])])
class PaymentEntity(
    @Id var id: String,
    @Column(nullable = false) @Enumerated(EnumType.STRING) var channel: PaymentChannel,
    @Column(name = "operation_type", nullable = false) @Enumerated(EnumType.STRING) var operation: PaymentOperation,
    @Column(name = "request_id", nullable = false) var requestId: String,
    @Column(name = "idempotency_key", nullable = false) var idempotencyKey: String,
    @Column(name = "merchant_id", nullable = false) var merchantId: String,
    @Column(name = "terminal_id") var terminalId: String? = null,
    var amountMinor: Long? = null,
    @Column(nullable = false) var currency: String,
    @Column(nullable = false) @Enumerated(EnumType.STRING) var status: PaymentStatus,
    @Column(nullable = false) var responseCode: String,
    @Column(nullable = false) var stan: String,
    var rrn: String? = null,
    var originalTransactionId: String? = null,
    @Column(length = 4000, nullable = false) var isoSnapshot: String,
    @Column(nullable = false) var createdAt: Instant = Instant.now(),
    @Column(nullable = false) var updatedAt: Instant = Instant.now()
)

/** Immutable lifecycle record.  This is the support timeline; current transaction state is never the only evidence. */
@Entity @Table(name = "payment_transaction_events")
class PaymentTransactionEventEntity(
    @Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null,
    @Column(name = "transaction_id", nullable = false) var transactionId: String,
    @Column(nullable = false) @Enumerated(EnumType.STRING) var status: PaymentStatus,
    @Column(nullable = false) var eventType: String,
    @Column(nullable = false, length = 500) var detail: String,
    var correlationId: String? = null,
    @Column(nullable = false) var createdAt: Instant = Instant.now()
)

enum class LedgerAccount { ACQUIRER_CLEARING, MERCHANT_PAYABLE, FEE_REVENUE, SETTLEMENT_PAYABLE }
@Entity @Table(name = "ledger_entries")
class LedgerEntryEntity(
    @Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null,
    @Column(nullable = false) var transactionId: String,
    @Column(nullable = false) @Enumerated(EnumType.STRING) var debitAccount: LedgerAccount,
    @Column(nullable = false) @Enumerated(EnumType.STRING) var creditAccount: LedgerAccount,
    @Column(nullable = false) var amountMinor: Long,
    @Column(nullable = false) var currency: String,
    @Column(nullable = false) var entryType: String,
    @Column(nullable = false) var createdAt: Instant = Instant.now()
)

enum class ReversalJobStatus { PENDING, IN_PROGRESS, RESOLVED, EXCEPTION }
@Entity @Table(name = "reversal_jobs", uniqueConstraints = [UniqueConstraint(columnNames = ["original_transaction_id"])])
class ReversalJobEntity(
    @Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null,
    @Column(name = "original_transaction_id", nullable = false, unique = true) var originalTransactionId: String,
    @Enumerated(EnumType.STRING) @Column(nullable = false) var status: ReversalJobStatus = ReversalJobStatus.PENDING,
    @Column(nullable = false) var attempts: Int = 0,
    var nextAttemptAt: Instant = Instant.now(),
    var lastError: String? = null,
    var resolvedAt: Instant? = null
)

enum class SettlementStatus { OPEN, CLOSED, RECONCILING, RECONCILED, EXCEPTION, PAID_OUT }
@Entity @Table(name = "settlement_batches", uniqueConstraints = [UniqueConstraint(columnNames = ["merchant_id", "business_date"])])
class SettlementBatchEntity(
    @Id var id: String,
    @Column(name = "merchant_id", nullable = false) var merchantId: String,
    @Column(name = "business_date", nullable = false) var businessDate: LocalDate,
    @Column(nullable = false) var transactionCount: Int,
    @Column(nullable = false) var grossMinor: Long,
    @Column(nullable = false) var refundMinor: Long,
    @Column(nullable = false) var feeMinor: Long,
    @Column(nullable = false) var netMinor: Long,
    @Column(nullable = false) @Enumerated(EnumType.STRING) var status: SettlementStatus = SettlementStatus.CLOSED,
    @Column(nullable = false) var createdAt: Instant = Instant.now(),
    var paidOutAt: Instant? = null
)

interface PaymentRepository : org.springframework.data.jpa.repository.JpaRepository<PaymentEntity, String> { fun findByChannelAndIdempotencyKey(channel: PaymentChannel, idempotencyKey: String): PaymentEntity?; fun findByMerchantId(merchantId: String): List<PaymentEntity> }
interface PaymentTransactionEventRepository : org.springframework.data.jpa.repository.JpaRepository<PaymentTransactionEventEntity, String> { fun findByTransactionIdOrderByCreatedAtAsc(transactionId: String): List<PaymentTransactionEventEntity> }
interface LedgerEntryRepository : org.springframework.data.jpa.repository.JpaRepository<LedgerEntryEntity, String>
interface ReversalJobRepository : org.springframework.data.jpa.repository.JpaRepository<ReversalJobEntity, String> { fun findByOriginalTransactionId(originalTransactionId: String): ReversalJobEntity? }
interface SettlementBatchRepository : org.springframework.data.jpa.repository.JpaRepository<SettlementBatchEntity, String> { fun findByMerchantIdAndBusinessDate(merchantId: String, businessDate: LocalDate): SettlementBatchEntity? }
