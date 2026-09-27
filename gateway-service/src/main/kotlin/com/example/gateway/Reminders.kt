package com.example.gateway

import jakarta.persistence.*
import org.springframework.scheduling.annotation.EnableScheduling
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.bind.annotation.*
import java.time.Instant

enum class ReminderType { REVERSAL_RECOVERY, SETTLEMENT_RECONCILIATION, FRAUD_REVIEW, TERMINAL_COMPLIANCE, CARD_PERSONALIZATION }
enum class ReminderStatus { OPEN, ACKNOWLEDGED, RESOLVED }

@Entity @Table(name = "operational_reminders", uniqueConstraints = [UniqueConstraint(columnNames = ["reminder_type", "reference_id", "status"])])
class OperationalReminderEntity(
    @Id @GeneratedValue(strategy = GenerationType.UUID) var id: String? = null,
    @Enumerated(EnumType.STRING) @Column(name = "reminder_type", nullable = false) var type: ReminderType,
    @Column(name = "reference_id", nullable = false) var referenceId: String,
    @Column(nullable = false, length = 1000) var message: String,
    @Column(nullable = false) var dueAt: Instant,
    @Enumerated(EnumType.STRING) @Column(nullable = false) var status: ReminderStatus = ReminderStatus.OPEN,
    @Column(nullable = false) var createdAt: Instant = Instant.now(),
    var acknowledgedAt: Instant? = null,
    var resolvedAt: Instant? = null
)

interface OperationalReminderRepository : org.springframework.data.jpa.repository.JpaRepository<OperationalReminderEntity, String> {
    fun findByTypeAndReferenceIdAndStatus(type: ReminderType, referenceId: String, status: ReminderStatus): OperationalReminderEntity?
    fun findByStatusOrderByDueAtAsc(status: ReminderStatus): List<OperationalReminderEntity>
}

@Service
class ReminderService(private val reminders: OperationalReminderRepository) {
    @Transactional fun open(type: ReminderType, referenceId: String, message: String, dueAt: Instant = Instant.now()): OperationalReminderEntity = reminders.findByTypeAndReferenceIdAndStatus(type, referenceId, ReminderStatus.OPEN) ?: reminders.save(OperationalReminderEntity(type = type, referenceId = referenceId, message = message, dueAt = dueAt))
    fun openReminders() = reminders.findByStatusOrderByDueAtAsc(ReminderStatus.OPEN)
    @Transactional fun acknowledge(id: String): OperationalReminderEntity { val reminder = reminders.findById(id).orElseThrow { IllegalArgumentException("Reminder not found") }; reminder.status = ReminderStatus.ACKNOWLEDGED; reminder.acknowledgedAt = Instant.now(); return reminders.save(reminder) }
    @Transactional fun resolve(id: String): OperationalReminderEntity { val reminder = reminders.findById(id).orElseThrow { IllegalArgumentException("Reminder not found") }; reminder.status = ReminderStatus.RESOLVED; reminder.resolvedAt = Instant.now(); return reminders.save(reminder) }
}

@Component @EnableScheduling
class OperationalReminderScheduler(
    private val reversalJobs: ReversalJobRepository,
    private val fraudCases: FraudCaseRepository,
    private val cardOrders: CardPersonalizationOrderRepository,
    private val reminderService: ReminderService
) {
    /** Produces work items only; it never retries or changes a financial transaction itself. */
    @Scheduled(fixedDelayString = "\${gateway.reminders.interval-ms:60000}")
    fun createOperationalReminders() {
        reversalJobs.findAll().filter { it.status in setOf(ReversalJobStatus.PENDING, ReversalJobStatus.EXCEPTION) }.forEach { reminderService.open(ReminderType.REVERSAL_RECOVERY, it.id!!, "Reversal for ${it.originalTransactionId} needs recovery", it.nextAttemptAt) }
        fraudCases.findAll().filter { it.status in setOf(FraudCaseStatus.OPEN, FraudCaseStatus.UNDER_REVIEW) }.forEach { reminderService.open(ReminderType.FRAUD_REVIEW, it.id!!, "Fraud case ${it.ruleCode} requires review") }
        cardOrders.findAll().filter { it.status in setOf(CardPersonalizationStatus.REQUESTED, CardPersonalizationStatus.APPROVED, CardPersonalizationStatus.QUEUED) }.forEach { reminderService.open(ReminderType.CARD_PERSONALIZATION, it.id, "Card order ${it.id} is awaiting personalization or activation") }
    }
}

@RestController @RequestMapping("/api/v1/admin/reminders")
class ReminderController(private val service: ReminderService) {
    @GetMapping fun open() = service.openReminders()
    @PostMapping("/{id}/acknowledge") fun acknowledge(@PathVariable id: String) = service.acknowledge(id)
    @PostMapping("/{id}/resolve") fun resolve(@PathVariable id: String) = service.resolve(id)
}
